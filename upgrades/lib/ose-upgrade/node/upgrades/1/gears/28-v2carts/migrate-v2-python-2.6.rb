module OpenShiftMigration
  module Number1
    module V2Carts
  class Python26Migration
    def post_process(user, progress, env)
      output = "applying python-2.6 migration post-process\n"


      Util.rm_env_var(user.homedir, 'OPENSHIFT_PYTHON_LOG_DIR')

      cartridge_dir = File.join(user.homedir, 'python')

      FileUtils.ln_sf('/usr/lib64/httpd/modules', cartridge_dir)
      FileUtils.ln_sf('/etc/httpd/conf/magic', File.join(cartridge_dir, 'etc', 'magic'))

      Util.add_cart_env_var(user, 'python', 'OPENSHIFT_PYTHON_VERSION', '2.6')
      Util.add_cart_env_var(user, 'python', 'OPENSHIFT_PYTHON_PATH_ELEMENT',
                            File.join(cartridge_dir, 'bin'))

      FileUtils.mkpath(File.join(cartridge_dir, 'virtenv'))

      directories = %w(logs virtenv)
      output << Util.move_directory_between_carts(user, 'python-2.6', 'python', directories)

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP',   'OPENSHIFT_PYTHON_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_PYTHON_PORT')

      output
    end
  end
    end
  end
end
