require_relative '22-postgres/migrate'
require_relative '24-httpd-frontend/migrate-frontend'
require_relative '28-v2carts/migrate-v2'

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
      o = ""
      out, r = OpenShiftMigration::Number1::Postgres.migrate(params)
      o += out
      return o, r if r != 0
      out, r = OpenShiftMigration::Number1::FrontEnd.migrate(params)
      o += out
      return o, r if r != 0
      out, r = OpenShiftMigration::Number1::V2Carts.migrate(params)
      o += out
      return o, r
    end
  end
end
