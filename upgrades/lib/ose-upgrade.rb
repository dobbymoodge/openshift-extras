
#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module OSEUpgrader
  OUT_OF_SEQUENCE = 255
  class Abstract

    def initialize(params = {})
      @params = params
    end

    # steps this upgrader can perform, in the order needed
    def implemented_steps
      []
    end

    # what we are trying to upgrade - generic host, broker, node
    def self.upgrade_target; "host"; end
    def upgrade_target; self.class.upgrade_target; end

    def initial_state(upgrade_number = nil)
      { }
    end

    def upgrade_state=(state)
      @upgrade_state = state
    end

    def set_step_status(step, to)
      state = get_step_state_data(step)
      state['previous_status'] = state['status']
      verbose "Setting #{self.upgrade_target} step '#{step}' status to #{to}"
      state['status'] = to
    end

    def get_step_state_data(step)
      steps_hash = @upgrade_state['steps'] ||= {}
      target_hash = steps_hash[upgrade_target()] ||= {}
      return target_hash[step] ||= {'status' => 'NONE'}
    end

    def get_step_status(step)
      return get_step_state_data(step)['status']
    end

    def get_next_step
      step = nil
      self.implemented_steps.each do |s|
        case get_step_status(s)
        when 'NONE', 'FAILED'
          step = s
          break
        when 'UPGRADING'
          do_fail "SHOULD NOT HAPPEN: step '#{s}' has state 'UPGRADING'"
          exit 1
        end
      end
      return step # nil means "nothing left to do here"
    end

    def steps_complete?
      get_next_step.nil?
    end

    def run_upgrade_step(step)
      rc =
      if implemented_steps.include? step
        next_step = self.get_next_step
        if next_step.nil?
          do_warn "All steps complete - no need to re-run step '#{step}'"
          OUT_OF_SEQUENCE
        elsif get_step_status(step) == 'COMPLETE'
          do_warn "Already ran step '#{step}' - please run step '#{next_step}' next"
          OUT_OF_SEQUENCE
        elsif next_step != step
          do_warn "Not ready for step '#{step}' yet - please run step '#{next_step}'"
          OUT_OF_SEQUENCE
        elsif @params[:skip]
          set_step_status(step, 'COMPLETE')
          if step = get_next_step
            verbose "Next step is '#{step}'"
          end
          0
        else
          begin
            set_step_status(step, 'UPGRADING')
            rc = self.send("run_upgrade_step_#{step}", @upgrade_state)
            set_step_status(step, (rc==0)?'COMPLETE':'FAILED')
            if rc==0 and step = get_next_step
              verbose "Next step is '#{step}'"
            end
            rc
          rescue Exception => e
            set_step_status(step, 'FAILED')
            do_fail "The '#{step}' upgrade step failed: #{e.pretty_inspect}"
          end
        end
      else
        do_fail "The '#{step}' upgrade step is not implemented for this host"
      end
      return rc
    end

    # now the upgrade steps should look like:
    def run_upgrade_step_example(upgrade_state)
      # do some stuff...
      return 0 #or, return an error code if something went wrong
    end

    ######## UTILITIES ########

    def called_from; caller[1][/`([^']*)'/, 1]; end
    def eputs(msg); $stderr.write "\e[#{31}m#{msg}\e[0m\n"; end
    def wputs(msg); $stderr.write "\e[#{33}m#{msg}\e[0m\n"; end

    def debug(msg)
      return 0 unless @params[:debug]
      Logger.log(msg = "DEBUG: #{msg}\n")
      $stdout.write msg
      return 0
    end

    def verbose(msg)
      Logger.log(msg = "INFO: #{msg}\n")
      @params[:verbose] and $stdout.write msg
      return 0
    end

    def do_fail(msg)
      Logger.log(msg = "ERROR: #{called_from}\n" + msg)
      eputs msg
      return 1
    end

    def do_warn(msg)
      Logger.log(msg = "WARN: #{called_from}\n" + msg)
      wputs msg
      return 1
    end

    def run_script(script)
      script_status = @upgrade_state['run_scripts'] ||= {}
      if script_status[script]=='COMPLETE'
        verbose "skipping #{script} -- already ran successfully"
        return 0, ""
      end
      verbose "running #{script}"
      output = `#{script} 2>&1`
      rc = $?.exitstatus
      if $?.success?
        verbose "#{script} ran without error:\n--BEGIN OUTPUT--\n#{output}\n--END #{script} OUTPUT--"
        script_status[script] = 'COMPLETE'
      else
        do_fail "#{script} had errors:\n--BEGIN OUTPUT--\n#{output}\n--END #{script} OUTPUT--"
        script_status[script] = 'FAILED'
      end
      return rc, output
    end

    # shortcut for File.dirname(__FILE__) + script
    def run_script_relative(from, *script)
      run_script File.join(File.dirname(from), *script.map {|s| s.to_s})
    end

    # shortcut for File.dirname(__FILE__) + dir + scripts
    # If any fail (nonzero rc), execution ends
    def run_scripts_in(from, *dir)
      rc, output = 0, ""
      dir = File.join(File.dirname(from), *dir.map {|s| s.to_s})
      verbose "Running upgrade scripts in #{dir}"
      any_ran = false
      Dir.entries(dir).sort.each do |script|
        file = File.join dir, script
        next if File.directory? file
        next if !File.executable? file
        next if script.start_with? '.'
        any_ran = true
        rc, o = run_script(file)
        output += o
        break if rc != 0
      end
      if any_ran
        return rc, output
      else
        do_fail "no executable scripts found in #{dir} !!"
        return 1, output
      end
    end

  end

  class Logger
    LOG_FILE = ENV['OPENSHIFT_UPGRADE_LOG'] || '/var/log/openshift/upgrade.log'
    def self.file=(file)
      @file = file
    end
    def self.file
      @file ||= LOG_FILE
    end
    def self.log(msg)
      # not very efficient to open the file every time, but this is not
      # high-traffic so not a problem.
      File.open(self.file, 'a') {|f| f.write msg}
    end
  end #logger
end # OSEUpgrader module
