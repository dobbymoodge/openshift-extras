require_relative 'httpd-frontend/migrate-frontend'
require_relative 'v2-cartridges/migrate-v2'

module OpenShiftMigration
  module Number1
    extend self
    # Perform the migration of a single gear from OSE 1.1 to 1.2
    # Provided parameters are:
    #    uuid: gear's UUID
    #    gear_home: directory in which the gear lives
    #    gear_name: name for gear (first part of hostname before hyphen)
    #    namespace: gear owner's domain / namespace for this gear (second part)
    #    broker_host: host on which a broker for this installation can be found
    #    cloud_domain: the domain under which app hostnames are created
    #    hostname: hostname for this node (for logging)
    # Return values: output to report back to broker, return code for this migration
    def migrate(params = {})
      o1, r = OpenShiftMigration::Number1::FrontEnd.migrate(params)
      return o1, r if r != 0
      o2, r = OpenShiftMigration::Number1::V2Carts.migrate(params)
      return o1 + o2, r
    end
  end
end
