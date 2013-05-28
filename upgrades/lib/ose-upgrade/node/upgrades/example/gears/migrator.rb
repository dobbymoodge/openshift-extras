module OpenShiftMigration
  class NumberX
    # Perform the migration number X against a single gear
    # Provided parameters are:
    #    uuid: gear's UUID
    #    gear_home: directory in which the gear lives
    #    gear_name: name of gear (part of hostname before hyphen)
    #    namespace: gear owner's domain / namespace for this gear
    #    broker_host: host on which a broker for this installation can be found
    #    cloud_domain: the domain under which app hostnames are created
    # Return values: output to report back to broker, return code for this migration
    def self.migrate(params = {})
      return "No-op!", 0
    end
  end
end
