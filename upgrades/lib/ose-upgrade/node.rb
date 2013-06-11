require 'ose-upgrade/finder'
module OSEUpgrader
  class Node < Abstract
    extend Finder
    def self.upgrade_target; "node"; end

  end
end
