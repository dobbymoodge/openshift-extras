module OpenShiftMigration
  module Number1
    module V2Carts
  class JenkinsClient14Migration
    def post_process(user, progress, env)
      output = "applying jenkins-client-1.4 migration post-process\n"

      Util.rm_env_var(user.homedir, 'PATH_JENKINS_CLIENT')
      Util.rm_env_var(user.homedir, 'OPENSHIFT_CI_TYPE')

      output
    end
  end
end
  end
end
