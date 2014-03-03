require 'ose-upgrade'

module OSEUpgrader
  class Node
    class Number3 < Node

      def implemented_steps
        #%w[ pre outage rpms conf maintenance_mode test_gears_complete end_maintenance_mode ]
        %w[ pre outage rpms conf maintenance_mode test_gears_complete end_maintenance_mode ]
      end

      def run_upgrade_step_pre(state)
        rc, _ = run_scripts_in(__FILE__, 'pre')
        return rc
      end

      def run_upgrade_step_outage(state)
        rc, _ = run_scripts_in(__FILE__, 'outage')
        return rc
      end

      def run_upgrade_step_rpms(state)
        do_warn "This may take a while."
        rc, _ = run_scripts_in(__FILE__, 'rpms')
        return rc
      end

      def run_upgrade_step_conf(state)
        rc, _ = run_scripts_in(__FILE__, 'conf')
        return rc
      end

      def run_upgrade_step_maintenance_mode(state)
        rc, _ = run_scripts_in(__FILE__, 'maintenance_mode')
        return rc
      end

      def run_upgrade_step_test_gears_complete(state)
        rc, _ = run_scripts_in(__FILE__, 'test_gears_complete')
        return rc
      end

      def run_upgrade_step_end_maintenance_mode(state)
        rc, _ = run_scripts_in(__FILE__, 'end_maintenance_mode')
        return rc
      end

    end
  end
end
