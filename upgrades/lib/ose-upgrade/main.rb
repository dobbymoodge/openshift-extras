
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

require 'ose-upgrade'

module OSEUpgrader
  class Main < Abstract

    STATE_FILE = ENV['OPENSHIFT_UPGRADE_STATE'] || '/etc/openshift/upgrade/state.yaml'
    RELEASE_FILE = ENV['OPENSHIFT_RELEASE_FILE'] || '/etc/openshift-enterprise-release'
    VERSION_MAP = {
        0  => "1.1",
        1  => "1.2",
        2  => "2.0",
    }
    require 'yaml'
    require 'pp'

    def initialize(params = nil)
      @params = params || @params || {
        :wait => 2.0,
        :verbose => false,
        :command => 'status',
        :args => [],
      }
      @rpms = nil
      @host_is = {} # :broker, :node, :broker_node
      @upgrader = self
      @package_source = nil # :repo, :rhn, :rhsm
      @upgrade_state = {}

      # determine the upgrade state from file and settings
      load_upgrade_state
      if @params[:complete]
        verbose "Marking upgrade number #{@params[:complete]} complete."
        @upgrade_state = initial_state(@params[:complete]).merge('status' => 'COMPLETE')
      end
      next_upgrade_if_complete

      # at this point we can assume we have the right upgrade number
      @params[:number] = @upgrade_state['number']
      # so locate the appropriate number-specific upgrader(s)
      load_upgrader
    end

    def implemented_steps
      %w[ begin ]
    end

    def steps_complete?
      super && @upgrader.steps_complete?
    end

    def set_params(args)
      @params.merge! args
    end

  ######## EXECUTION #############

    def run_upgrade
      rc = run_command(@params[:command].downcase)
      determine_upgrade_status
      next_upgrade_if_complete
      save_upgrade_state
      return rc
    end

    def run_command(cmd)
      # status is left at complete if there are no further upgrades yet.
      # In that case, there is nothing to do but inform the user.
      cmd = 'status' if @upgrade_state['status'] == 'COMPLETE'

      case cmd
      when 'all'
        if steps_complete?
          verbose "All steps already complete."
          0
        else
          run_all
        end
      when 'status'
        show_status
      when *(self.implemented_steps)
        self.run_upgrade_step(cmd)
      else
        @upgrader.run_upgrade_step(cmd)
      end
    end

    def run_all
      while step = self.get_next_step
        rc = self.run_upgrade_step(step)
        return rc if rc != 0
      end
      while step = @upgrader.get_next_step
        rc = @upgrader.run_upgrade_step(step)
        return rc if rc != 0
      end
      return 0
    end

    def show_status
      number = @upgrade_state['number']
      version = VERSION_MAP[number]
      if @upgrade_state['status'] == 'COMPLETE'
        puts "Upgrade number #{number} to version #{version} is complete."
        next_upgrade_if_complete
        return 0
      end
      step = self.get_next_step
      if step.nil? && @upgrader
        step = @upgrader.get_next_step
      end
      debug @upgrade_state.pretty_inspect
      # no need to log status, so use "puts" not "verbose"
      puts "Current upgrade is number #{number} to version #{version}."
      if step
        puts "Step sequence:\n  #{(implemented_steps + @upgrader.implemented_steps).uniq.join ' '}"
        puts "Next step is: #{step}"
      else
        puts "Steps complete"
      end
      return 0
    end

    def run_upgrade_step_begin(state)
      num = state['number']
      verbose "Starting upgrade number #{num} to version #{VERSION_MAP[num]}."
      @upgrade_state['status'] = 'STARTED'
      source = self.detect_package_source
      if source == :rhn
        puts "In order to reconfigure your RHN channels, we will need credentials."
        STDOUT.write "What is your RHN username? "
        ENV['RHN_USER'] = STDIN.gets
        STDOUT.write "What is your RHN password (will not show)? "
        system "stty -echo"
        ENV['RHN_PASS'] = STDIN.gets
        system "stty echo"
        puts
      end
      rc, o = run_scripts_in(__FILE__, "host", "upgrades", num, source)
      File.open(RELEASE_FILE, 'w') do |file|
        file.write "OpenShift Enterprise #{VERSION_MAP[num]}\n"
        verbose "updating #{RELEASE_FILE}"
      end if rc == 0
      rc
    end

    def determine_upgrade_status
      return if @upgrader.get_next_step # steps remain, status stays same
      return if @upgrade_state['status'] == 'COMPLETE' # already determined!
      # no steps left; determine whether there *should* be or we are COMPLETE
      if @host_is[:broker] || @host_is[:node]
        # at least one of those upgraders must have been present and completed.
        @upgrade_state['status'] = 'COMPLETE'
        verbose "Upgrade to version #{VERSION_MAP[@upgrade_state['number']]} is complete."
      else
        # should the broker/node upgraders be there?
        load_rpm_list
        if @rpms['rubygem-openshift-origin-common']
          # *assume* that means broker or node is installed
          verbose "To continue the upgrade, install a specific upgrade package."
          verb = @rpms['openshift-enterprise-upgrade-broker'] ? 'update' : 'install'
          do_warn <<BROKER if @rpms['openshift-origin-broker'] && !@host_is[:broker]
You appear to have an OpenShift Enterprise broker installed;
please #{verb} the broker upgrade package to proceed with this upgrade.
  # yum #{verb} openshift-enterprise-upgrade-broker
BROKER
          verb = @rpms['openshift-enterprise-upgrade-node'] ? 'update' : 'install'
          do_warn <<NODE if @rpms['rubygem-openshift-origin-node'] && !@host_is[:node]
You appear to have an OpenShift Enterprise node installed;
please #{verb} the node upgrade package to proceed with this upgrade.
  # yum #{verb} openshift-enterprise-upgrade-node
NODE
        else
          do_warn <<HOST
You don't appear to have an OpenShift Enterprise broker or node installed.
If this is correct, you can just update supporting services manually with:

  # yum update

Then manually mark the upgrade complete with:

  # ose-upgrade --complete #{@upgrade_state['number']}
HOST
        end
      end
    end

    def next_upgrade_if_complete
      if @upgrade_state['status'] == 'COMPLETE' and
        version = VERSION_MAP[new_num = @upgrade_state['number'] + 1]

        verbose "Upgrade number #{new_num} to version #{version} is available to run."
        @upgrade_state = initial_state(new_num)
      end
    end

  ######## SETUP #############

    def load_upgrade_state
      if File.exists? STATE_FILE
        @upgrade_state = YAML.load_file(STATE_FILE)
      else
        @upgrade_state = initial_state
      end
    end

    def try_upgrader(type, params)
      upgrader = nil
      begin
        require "ose-upgrade/#{type}"
        verbose "OpenShift #{type} installed."
        @host_is[type] = true
        finder = case type
                 when :node; OSEUpgrader::Node
                 when :broker; OSEUpgrader::Broker
                 end
        if u = finder.find_upgrader(@params.merge(params))
          upgrader = u
        else
          do_warn "There is no #{type} upgrader for upgrade #{@params[:number]}"
        end
      rescue LoadError
        @host_is[type] = false
      rescue Finder::Error => e
        do_fail "Upgrader number #{@params[:number]} for #{type} failed to load: #{e.inspect}"
      end
      return upgrader
    end

    def load_upgrader
      node_upgrader = try_upgrader(:node, :main_upgrader => self)
      broker_upgrader = try_upgrader(:broker, :main_upgrader => self, :node_upgrader => node_upgrader)
      @host_is[:broker_node] = @host_is[:broker] && @host_is[:node]
      @upgrader = broker_upgrader || node_upgrader || self
      @upgrader.upgrade_state = @upgrade_state
      return @upgrader
    end

    def initial_state(upgrade_number = 0)
      super.merge('number' => upgrade_number, 'status' => "NONE")
    end

    def save_upgrade_state
      File.open(STATE_FILE, "w") do |file|
        file.write YAML.dump(@upgrade_state)
      end
    end

    def load_rpm_list
      return @rpms if @rpms
      verbose "loading list of installed packages"
      @rpms = {}
      `rpm -qa --qf '%{NAME}|%{VERSION}|%{RELEASE}\n'`.split.each do |rpm|
        rpm = rpm.split '|'
        @rpms[rpm[0]] = {
          :name => rpm[0],
          :version => rpm[1],
          :release => rpm[2],
        }
      end
      return @rpms
    end

    def detect_package_source
      return @package_source if @package_source
      load_rpm_list
      if File.exists? '/etc/sysconfig/rhn/systemid'
        @package_source = :rhn
        verbose "RHN subscription detected."
      elsif @rpms['subscription-manager'] && system('subscription-manager identity >& /dev/null')
        @package_source = :rhsm
        verbose "Subscription-manager subscription detected."
      else
        @package_source = :repo
        verbose "No subscription detected; assuming plain yum repos."
      end
      return @package_source
    end

  end #class
end # OSEUpgrader module
