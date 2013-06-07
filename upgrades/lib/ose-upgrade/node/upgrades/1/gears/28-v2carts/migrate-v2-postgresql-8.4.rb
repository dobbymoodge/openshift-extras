
module OpenShiftMigration
  module Number1
    module V2Carts
  class Postgresql84Migration
    def post_process(user, progress, env)
      output = "applying postgresql-8.4 migration post-process\n"

      username = Util.get_env_var_value(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_USERNAME')
      host     = Util.get_env_var_value(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_HOST')
      port     = Util.get_env_var_value(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_PORT')

      Util.rm_env_var(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_SOCKET')
      Util.rm_env_var(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_LOG_DIR')
      Util.rm_env_var(user.homedir, 'OPENSHIFT_POSTGRESQL_DB_PID')

      # Copy username to PGUSER env var
      Util.add_cart_env_var(user, 'postgresql', 'PGUSER', username)

      # Move old ENV vars
      env_vars = %w(USERNAME PASSWORD URL)
      env_vars.map! { |x| "OPENSHIFT_POSTGRESQL_DB_#{x}" }

      output << Util.move_gear_env_var_to_cart(user, 'postgresql', env_vars)
      cart_dir = PathUtils.join(user.homedir, 'postgresql')
      cart_env = PathUtils.join(cart_dir, 'env')
      Util.make_user_owned(cart_env, user)

      directories = %w(log data)
      output << Util.move_directory_between_carts(user, 'postgresql-8.4', 'postgresql', directories)

      # Apply the correct permissions to these files
      FileUtils.chmod(0700, PathUtils.join(cart_dir,'data'))
      FileUtils.chmod(0700, PathUtils.join(cart_dir,'socket'))

      # Also ensure the .pgpass matches the v2 format
      PathUtils.join(user.homedir,'.pgpass').tap do |target|
        FileUtils.chmod(0600, target)
        Util.replace_in_file(target, "^#{host}:#{port}",'*:*')
      end

      conf_dir = PathUtils.join(cart_dir,'conf')

      # Ensure our new conf files are used in the v2 cart
      %w(postgresql.conf pg_hba.conf).each do |file|
        src = PathUtils.join(conf_dir,file)
        # Back up old files in case the user made changes
        "#{src}.bak".tap do |bak|
          # Make sure not to overwrite an existing backup in case we are rerunning
          FileUtils.cp(src, bak) unless File.exists?(bak)
        end
        FileUtils.cp_r(src, PathUtils.join(cart_dir,'data'), :remove_destination => true)
      end

      PathUtils.join(user.homedir,'.psqlrc').tap do |target|
        FileUtils.cp_r(PathUtils.join(conf_dir,'psqlrc'), target, :remove_destination => true)
        Util.make_user_owned(target, user)
      end

      # Make sure the file exists
      PathUtils.join(user.homedir,'.psql_history').tap do |file|
        FileUtils.mv(file, PathUtils.join(user.homedir,'app-root','data')) if File.exists?(file)
      end

      output
    end
  end
    end
  end
end
