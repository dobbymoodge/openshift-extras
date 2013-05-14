require 'openshift-origin-node/utils/shell_exec'

module OpenShiftMigration
  module Number1
    module V2Carts
  class Php53Migration
    def post_process(user, progress, env)
      output = "applying php-5.3 migration post-process\n"

      Util.rm_env_var(user.homedir, 'OPENSHIFT_PHP_LOG_DIR')
      # There was no PHPRC variable in v1, it was hard-coded in control scripts
      # Util.rm_env_var(user.homedir, 'PHPRC')

      cartridge_dir = File.join(user.homedir, 'php')

      FileUtils.ln_sf('/usr/lib64/httpd/modules', File.join(cartridge_dir, 'modules'))
      FileUtils.ln_sf('/etc/httpd/conf/magic', File.join(cartridge_dir, 'conf', 'magic'))

      FileUtils.rm_f(File.join(user.homedir, '.pearrc'))

      php_dir = File.join(user.homedir, 'php')
      pearrc = File.join(user.homedir, '.pearrc')

      spawn_ops = { chdir: user.homedir,
                    unsetenv_others: true,
                    uid: user.uid,
                    expected_exitstatus: 0
                  }

      OpenShift::Utils.oo_spawn("pear config-create #{php_dir}/phplib/pear/ #{pearrc}", spawn_ops)
      OpenShift::Utils.oo_spawn("pear -c #{pearrc} config-set php_ini #{php_dir}/configuration/etc/php.ini", spawn_ops)
      OpenShift::Utils.oo_spawn("pear -c #{pearrc} config-set auto_discover 1", spawn_ops)

      Util.add_cart_env_var(user, 'php', 'OPENSHIFT_PHP_VERSION', '5.3')
      Util.add_cart_env_var(user, 'php', 'PHPRC', "#{php_dir}/configuration/etc/php.ini")

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP',   'OPENSHIFT_PHP_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_PHP_PORT')

      directories = %w(logs sessions phplib)
      output << Util.move_directory_between_carts(user, 'php-5.3', 'php', directories)

      output
    end
  end
    end
  end
end
