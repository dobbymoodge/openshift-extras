# = upgrade.rb: node host upgrade and migration integration via mcollective
#
# Author:: Red Hat
#
# Copyright © 2013 Red Hat, Inc. All rights reserved
#
# == Description
#
# upgrade.rb for mcollective is used during upgrades of OpenShift Enterprise
# node hosts.
#
# Like the rest of the upgrade code, this code should be as simple, generic,
# and future-proof as possible. Specifics for each upgrade must be reserved
# for upgrade-specific code. Expect this same code to be used for upgrading
# very old versions as well as the latest. It should not be changed if it is
# at all possible, and then only to make optional additions.
#
require 'rubygems'
require 'pp'

module MCollective
  module Agent

    class Oseupgrade < RPC::Agent

      #
      # Migrate a gear from previous to current migration number
      #
      def migrate_action
        Log.instance.info("migrate_action call / request = #{request.pretty_inspect}")
        validate :uuid, /^[a-zA-Z0-9]+$/
        validate :gear_name, /^[a-zA-Z0-9]+$/
        validate :number, /^\d+$/
        validate :namespace, /^.+$/
        output = ""
        exitcode = 0
        begin
          # since upgrades and migrations are fairly rare in normal operation,
          # only load the code after there is an actual migration request
          # (require will only do this once)
          require "ose-upgrade/node/gears/migration"
          params = [:uuid, :gear_name, :namespace, :number].inject(Hash.new) {|p,k| p[k] = request[k]; p}
          output, exitcode = OpenShiftMigration::migrate(params)
        rescue LoadError => e
          exitcode = 127
          output += "Migrate not supported. #{e.message} #{e.backtrace}\n"
        rescue Exception => e
          exitcode = 1
          output += "Gear failed to migrate with exception: #{e.message}\n#{e.backtrace}\n"
        end
        Log.instance.info("migrate_action (#{exitcode})\n------\n#{output}\n------)")

        reply[:output] = output
        reply[:exitcode] = exitcode
        reply.fail! "migrate_action failed #{exitcode}.  Output #{output}" unless exitcode == 0
      end

      def gear_upgrades_complete_action
        Log.instance.info("gear_upgrades_complete_action call / request = #{request.pretty_inspect}")
        require 'fileutils'
        FileUtils.touch('/etc/openshift/upgrade/2/gear_upgrades_complete')
        reply[:exitcode] = 0
      end

      def ping_action
        Log.instance.info("ping_action call / request = #{request.pretty_inspect}")
        reply[:exitcode] = 0
      end

    end
  end
end
