module OpenShift
  module Broker
    class MigratorX < OpenShift::Broker::Migrator
      # just override the hooks necessary for the migration.

      # Hook that is called prior to the entire run of gear migrations
      def pre_global_run(params = {})
        puts "Preparing for number X gear migration run..."
      end

      # Hook that is called prior to each individual gear migration
      # Params:
      #   uuid: gear UUID to be migrated
      def pre_gear_migration(params = {})
        puts "About to migrate gear #{params[:uuid]}"
      end

      # Hook that is called after each individual gear migration
      # Params:
      #   UUID: gear UUID that was migrated
      #   output: output from the gear migration
      #   exitcode: numeric return code from the gear migration
      def post_gear_migration(params = {})
        puts "Migration of gear #{params[:uuid]} completed with exit #{params[:exitcode]}."
      end

      # Hook that is called after the entire run of gear migrations
      def post_global_run(params = {})
        puts "Gear migration number X complete."
      end

    end
  end
end
