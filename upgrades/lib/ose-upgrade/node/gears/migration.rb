require 'rubygems'
require 'openshift-origin-common/config'
require 'etc'
require 'fileutils'
require 'socket'
require 'parseconfig'
require 'pp'

# This is generic gear-migration-management code that should never change,
# or at least only change additively, such that it is future-proof;
# i.e. if the customer is at migration level 1 and needs to run gear migrations
# through number 7, changes introduced to this code with version 7
# must not affect gear migrations 2, 3, and on.
#
# Basically, don't change anything here unless absolutely necessary,
# and then only in a way that adds functionality without changing or
# removing what exists.

module OpenShiftMigration
  # entry point to migrating a single gear a single step.
  # Expected parameters (passed in symbol => value hash):
  #   uuid: UUID of gear to be migrated
  #   gear_name: name of gear (part of hostname before hyphen)
  #   namespace: domain/namespace of the application this gear belongs to
  #   number: migration number run on the gear -- used to
  #            locate the code specific to this migration.
  def self.migrate(params)
    # ensure the migration is available and loaded
    # Migrators must have class name OpenShiftMigration::Number<num>
    # and must live in migrations/<num>/ with migrator.rb as the entry point
    migrator = "Number#{params[:number]}"
    if OpenShiftMigration.const_defined? migrator
      migrator = OpenShiftMigration.const_get migrator
    else
      begin
        require "ose-upgrade/node/upgrades/#{params[:number]}/gears/migrator"
        migrator = OpenShiftMigration.const_get migrator
      rescue LoadError => e
        return "Invalid migration number: #{params[:number]}\n#{e.inspect}", 255
      rescue NameError => e
        return "File #{m} did not define class OpenShiftMigration::#{migrator}", 255
      end
    end

    gear_home = "#{get_config_value('GEAR_BASE_DIR')}/#{params[:uuid]}"

    unless (File.exists?(gear_home) && !File.symlink?(gear_home))
      exitcode = 127
      output = "Gear not found to migrate: #{gear_home}\n"
      return output, exitcode
    end

    start_time = (Time.now.to_f * 1000).to_i
    output, exitcode = begin
      migrator.migrate params.merge(
        gear_home: gear_home,
        broker_host: get_config_value('BROKER_HOST'),
        cloud_domain: get_config_value('CLOUD_DOMAIN'),
        hostname: `hostname`
      )
    rescue Exception => e
      [e.pretty_inspect, 1]
    end

    total_time = (Time.now.to_f * 1000).to_i - start_time
    output += "\n### time_migrate_on_node_measured_from_node=#{total_time} ###\n"
    return output, exitcode
  end

  def self.get_config_value(key)
    @node_config ||= OpenShift::Config.new  # node conf
    @node_config.get(key)
  end
end
