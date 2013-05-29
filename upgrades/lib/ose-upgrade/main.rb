
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
    require 'rubygems'
    require 'yaml'
    require 'pp'

    def initialize(options = nil)
      @params = options || @params || {
        :wait => 2.0,
        :verbose => false,
        :number => 1,
        :command => 'status',
        :args => [],
      }
      @rpms = {}
      @host_is = {} # :broker, :node, :broker_node
      @upgrader = self
      @package_source = nil # :repo, :rhn, :rhsm
      @upgrade_state = {}

      load_upgrader
      load_upgrade_state
    end

    def implemented_steps
      %w[ channels ]
    end

    def is_complete?
      super && @upgrader.is_complete?
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

    def run_upgrade
      cmd = @params[:command].downcase
      rc = case cmd
      when 'all'
        if is_complete?
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
      save_upgrade_state
      return rc
    end

    def show_status
      step = self.get_next_step
      if step.nil? && @upgrader
        step = @upgrader.get_next_step
      end
      debug @upgrade_state.pretty_inspect
      if step
        puts "Step sequence:\n  #{(implemented_steps + @upgrader.implemented_steps).uniq.join ' '}"
        puts "Next step is: #{step}"
      else
        puts "Steps complete" if step.nil?
      end
      return 0
    end

    def run_upgrade_step_channels(state)
      source = self.detect_package_source
      rc, output = run_script_relative(__FILE__, "channels", @params[:number].to_s, source.to_s)
      rc
    end

  ######## SETUP #############

    def load_rpm_list
      verbose "loading list of installed packages"
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
      return @upgrader = broker_upgrader || node_upgrader || self
    end

    def load_upgrade_state
      if File.exists? STATE_FILE
        @upgrade_state = YAML.load_file(STATE_FILE)
      else
        @upgrade_state = @upgrader.initial_state
      end
      @upgrader.upgrade_state = @upgrade_state
    end

    def initial_state
      super.merge('number' => @params[:number], 'status' => "NONE")
    end

    def save_upgrade_state
      File.open(STATE_FILE, "w") do |file|
        file.write YAML.dump(@upgrade_state)
      end
    end

    def detect_package_source
      return @package_source if @package_source
      @rpms ||= load_rpm_list
      if File.exists? '/etc/sysconfig/rhn/systemid'
        @package_source = :rhn
        verbose "RHN subscription detected."
      elsif @rpms['subscription-manager'] && system('subscription-manager identity >& /dev/null') == 0
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
