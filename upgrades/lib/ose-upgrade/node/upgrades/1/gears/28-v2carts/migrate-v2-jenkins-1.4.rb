module OpenShiftMigration
  module Number1
    module V2Carts
  class Jenkins14Migration
    def post_process(user, progress, env)
      output = "applying jenkins-1.4 migration post-process\n"

      Util.rm_env_var(user.homedir, 'OPENSHIFT_JENKINS_LOG_DIR')

      env_vars = %w(USERNAME PASSWORD)
      env_vars.map! { |x| "JENKINS_#{x}" }

      output << Util.move_gear_env_var_to_cart(user, 'jenkins', env_vars, false)

      directories = %w(logs)
      output << Util.move_directory_between_carts(user, 'jenkins-1.4', 'jenkins', directories)

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP',   'OPENSHIFT_JENKINS_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_JENKINS_PORT')

      output
    end
  end
    end
  end
end
