module OpenShiftMigration
  module Number1
    module V2Carts
  class Diy01Migration
    def post_process(user, progress, env)
      output = "applying diy-0.1 migration post-process\n"

      Util.rm_env_var(user.homedir, 'OPENSHIFT_DIY_LOG_DIR')

      cart_dir = File.join(user.homedir, 'diy')

      directories = %w(logs)
      output << Util.move_directory_between_carts(user, 'diy-0.1', 'diy', directories)

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP',   'OPENSHIFT_DIY_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_DIY_PORT')

      output
    end
  end
    end
  end
end
