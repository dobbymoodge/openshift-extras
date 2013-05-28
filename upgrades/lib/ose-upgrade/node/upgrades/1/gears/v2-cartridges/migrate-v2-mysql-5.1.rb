
module OpenShiftMigration
  module Number1
    module V2Carts
  class Mysql51Migration
    def post_process(user, progress, env)
      output = "applying mysql-5.1 migration post-process:\n"

      Util.rm_env_var(user.homedir, 'OPENSHIFT_MYSQL_DB_SOCKET')
      Util.rm_env_var(user.homedir, 'OPENSHIFT_MYSQL_DB_LOG_DIR')

      env_vars = %w(USERNAME PASSWORD URL LOG_DIR)
      env_vars.map! { |x| "OPENSHIFT_MYSQL_DB_#{x}" }

      output << Util.move_gear_env_var_to_cart(user, 'mysql', env_vars)
      cart_dir = File.join(user.homedir, 'mysql')
      cart_env = File.join(cart_dir, 'env')
      Util.make_user_owned(cart_env, user)

      directories = %w(log data)
      output << Util.move_directory_between_carts(user, 'mysql-5.1', 'mysql', directories)

      output
    end
  end
    end
  end
end
