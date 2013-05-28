require 'ose-upgrade/finder'
module OSEUpgrader
  class Node < Abstract
    extend Finder
    def self.upgrade_target; "node"; end

    def initial_state
      super.merge(@params[:main_upgrader].initial_state)
    end

    def upgrade_state=(state)
      super
      @params[:main_upgrader].upgrade_state = state
    end

      def run_upgrade_step_pre(state)
        rc, o = run_scripts_in(__FILE__, 'pre')
        return rc
      end

      def run_upgrade_step_yum(state)
        source = @params[:main_upgrader].detect_package_source
        rc, o = run_scripts_in(__FILE__, 'yum', source.to_s)
        return rc
      end

      def run_upgrade_step_rpms(state)
        rc, o = run_scripts_in(__FILE__, 'rpms')
        return rc
      end

      def run_upgrade_step_conf(state)
        rc, o = run_scripts_in(__FILE__, 'conf')
        return rc
      end

      def run_upgrade_step_data(state)
        rc, o = run_scripts_in(__FILE__, 'data')
        return rc
      end

      def run_upgrade_step_gears(state)
        rc, o = run_scripts_in(__FILE__, 'gears')
        return rc
      end

  end
end
