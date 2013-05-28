require 'ose-upgrade/finder'
module OSEUpgrader
  class Broker < Abstract
    extend Finder
    def self.upgrade_target; "broker"; end

    def initial_state
      [@params[:main_upgrader], @params[:node_upgrader]].inject({}) { |state,u|
        u ? state.merge(u.initial_state) : state
      }
    end

    def upgrade_state=(state)
      super
      [@params[:main_upgrader], @params[:node_upgrader]].each {|u| u && u.upgrade_state = state}
    end

    def run_upgrade_step(step)
      # When also a node, run node steps in lockstep (before broker).
      # This implies broker steps MUST include node steps.
      if node = @params[:node_upgrader]
        if node.get_next_step == step
          rc = node.run_upgrade_step(step)
          return rc if rc != 0
        end
      end
      rc = super
    end
  end
end
