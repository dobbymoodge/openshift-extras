require 'ose-upgrade'
require 'ose-upgrade/broker'

module OSEUpgrader
  class Broker
    class NumberX < Broker

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
        rc, o = run_scripts_in(__FILE__, 'conf')
        return rc
      end

      def run_upgrade_step_start_node(state)
        0 # just a passthrough for the node upgrader step
      end

      def run_upgrade_step_confirm_nodes(state)
        rc, o = run_scripts_in(__FILE__, 'confirm_nodes')
        return rc
      end

      def run_upgrade_step_data(state)
        rc, o = run_scripts_in(__FILE__, 'data')
        return rc
      end

      def run_upgrade_step_gears(state)
        do_warn "This may take a while."
        rc, o = run_scripts_in(__FILE__, 'gears')
        return rc
      end

      def run_upgrade_step_start_broker(state)
        rc, o = run_scripts_in(__FILE__, 'start')
        return rc
      end

    end
  end
end
