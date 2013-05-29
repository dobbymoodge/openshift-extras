require 'ose-upgrade'

module OSEUpgrader
  class Node
    class Number1 < Node

      def implemented_steps
        %w[ pre rpms conf start_node ]
      end

      def run_upgrade_step_pre(state)
        rc, o = run_scripts_in(__FILE__, 'pre')
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
        rc, o = run_scripts_in(__FILE__, 'start')
        return rc
      end

    end
  end
end
