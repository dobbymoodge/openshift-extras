require 'ose-upgrade'
require 'ose-upgrade/broker'

module OSEUpgrader
  class Broker
    class Number1 < Broker

      def initialize(params = {})
        @params = params
      end

      def implemented_steps
        @params[:node_upgrader] ?
        %w[ outage rpms conf start_node confirm_nodes data gears start_broker] :
        %w[ outage rpms conf confirm_nodes data gears start_broker]
      end

      def run_upgrade_step_outage(state)
        rc, o = run_scripts_in(__FILE__, 'outage')
        do_warn "Please upgrade nodes in parallel, prior to the confirm_nodes step" if rc == 0
        return rc
      end

      def run_upgrade_step_rpms(state)
        do_warn "This may take a while."
        rc, o = run_scripts_in(__FILE__, 'rpms')
        return rc
      end

      def run_upgrade_step_conf(state)
        rc = 0
        unless get_step_state_data('conf')['skip_first']
          rc, o = run_scripts_in(__FILE__, 'conf')
          return rc if rc != 0
        end
        if @params[:node_upgrader]
          # run configuration changes necessary only to coexist
          rc, o = run_scripts_in(__FILE__, 'conf_with_node')
          return rc if rc == 0
          get_step_state_data('conf')['skip_first']=true
        end
        rc
      end

      def run_upgrade_step_start_node(state)
        0 # just a passthrough for the node upgrader step
      end

      def run_upgrade_step_confirm_nodes(state)
        rc, o = run_scripts_in(__FILE__, 'confirm_nodes')
        return rc
      end

      def run_upgrade_step_data(state)
        # this needs to run on only one broker
        return claim_upgrade_step("data") do
          rc, o = run_scripts_in(__FILE__, 'data')
          rc
        end
      end

      def run_upgrade_step_gears(state)
        # this needs to run on only one broker
        return claim_upgrade_step("gears") do
          do_warn "This may take a while."
          continue = state['steps']['broker']['gears']['previous_status'] == 'FAILED'
          rc, o = run_script("#{File.dirname(__FILE__)}/gears/migrator --number=1 #{continue ? '--continue' : ''}")
          rc
        end
      end

      def run_upgrade_step_start_broker(state)
        rc, o = run_scripts_in(__FILE__, 'start')
        return rc
      end


      # In a multi-broker situation, we need a semaphore for owning
      # the steps that we want only one broker to handle.
      # This depends on the codebase and might need to change per upgrade,
      # which is why it's here and not in the superclass.
      def claim_upgrade_step(step, &block)
        # and because it requires the codebase, and ose-upgrade runs under native ruby,
        # we have to shell out to scl-ized script to determine this
        lock = "oseupgrade_1_#{step}"
        rc, o = run_script("#{File.dirname(__FILE__)}/step_lock #{lock}")
        return rc if rc != 0
        if o.match(/SKIP/)
          verbose "Another broker completed this step; skipping"
          return 0
        end
        # ok - this broker will execute the step
        rc = block.call
        return rc if rc != 0
        rc, o = run_script("#{File.dirname(__FILE__)}/step_lock #{lock} done")
        return rc
      end

    end
  end
end
