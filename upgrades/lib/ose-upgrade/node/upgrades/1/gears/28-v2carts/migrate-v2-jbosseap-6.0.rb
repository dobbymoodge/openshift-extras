module OpenShiftMigration
  module Number1
    module V2Carts
  class Jbosseap60Migration
    def post_process(user, progress, env)
      output = "applying jbosseap-6.0 migration post-process\n"

      cart_name = 'jbosseap'

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP', 'OPENSHIFT_JBOSSEAP_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_JBOSSEAP_HTTP_PORT')

      Util.add_cart_env_var(user, cart_name, "OPENSHIFT_JBOSSEAP_VERSION", "6.0")

      cartridge_dir = File.join(user.homedir, cart_name)

      # Prune old variables
      Util.rm_env_var(user.homedir, 'OPENSHIFT_JBOSSEAP_LOG_DIR', 'PATH')

      # Hang on to these, we'll need them later...
      java_home = Util.get_env_var_value(user.homedir, 'JAVA_HOME')
      m2_home = Util.get_env_var_value(user.homedir, 'M2_HOME')

      if !java_home
        if File.exists?(File.join(user.homedir, "app-root", "repo", ".openshift", "markers", "java7"))
          java_home="/etc/alternatives/java_sdk_1.7.0"
        else
          java_home="/etc/alternatives/java_sdk_1.6.0"
        end

        Util.add_gear_env_var(user, "JAVA_HOME", java_home)
      end

      if !m2_home
        m2_home="/etc/alternatives/maven-3.0"
        Util.add_gear_env_var(user, "M2_HOME", m2_home)
      end

      # Move vars from the gear to the cart
      xfer_cart_vars = %w(JAVA_HOME M2_HOME OPENSHIFT_JBOSSEAP_CLUSTER OPENSHIFT_JBOSSEAP_CLUSTER_REMOTING)
      Util.move_gear_env_var_to_cart(user, cart_name, xfer_cart_vars)

      # Reconstruct PATH (normally happens during v2 install)
      Util.add_cart_env_var(user, cart_name, 'OPENSHIFT_JBOSSEAP_PATH_ELEMENT', "#{java_home}/bin:#{m2_home}/bin")

      modules_jar = File.join(cartridge_dir, 'jboss-modules.jar')
      modules_dir = File.join(cartridge_dir, 'modules')

      FileUtils.ln_sf('/etc/alternatives/jbosseap-6.0/jboss-modules.jar', modules_jar)
      FileUtils.ln_sf('/etc/alternatives/jbosseap-6.0/modules', modules_dir)

      Util.make_user_owned(modules_jar, user)
      Util.make_user_owned(modules_dir, user)

      logs_dir = File.join(cartridge_dir, 'logs')
      log_dir = File.join(cartridge_dir, 'standalone/log')

      FileUtils.ln_sf(log_dir, logs_dir)

      repo_deployments_dir = File.join(user.homedir, 'app-root/runtime/repo/deployments/')
      active_deployments_dir = File.join(cartridge_dir, 'standalone/deployments')

      Dir.glob(File.join(repo_deployments_dir, '*')).each do |file|
        FileUtils.cp_r(file, active_deployments_dir, :remove_destination => true)
      end

      output << Util.move_directory_between_carts(user, 'jbosseap-6.0', 'jbosseap', ['logs'])

      output
    end
  end
    end
  end
end
