module OpenShiftMigration
  module Number1
    module V2Carts
  class Haproxy14Migration

    def mv_if_exists(src_file, target_file, user)
      FileUtils.mv(src_file, target_file) if File.exist? src_file
      Util.make_user_owned(target_file, user)
      FileUtils.chmod(0600, target_file)
    end

    def post_process(user, progress, env)
      output = "applying haproxy-1.4 migration post-process\n"
      Util.rm_env_var(user.homedir, 'OPENSHIFT_HAPROXY_LOG_DIR')
      Util.mv_env_var_value(user, 'OPENSHIFT_HAPROXY_INTERNAL_IP', 'OPENSHIFT_HAPROXY_IP')

      directories = %w(logs conf)
      output << Util.move_directory_between_carts(user, 'haproxy-1.4', 'haproxy', directories)

      Util.add_gear_env_var(user, 'OPENSHIFT_HAPROXY_PORT', '8080')
      Util.add_gear_env_var(user, 'OPENSHIFT_HAPROXY_STATUS_PORT', '8080')

      ssh_src_dir = File.join(user.homedir, "haproxy-1.4", ".ssh")
      ssh_target_dir = File.join(user.homedir, ".openshift_ssh")
      FileUtils.mv(ssh_src_dir , ssh_target_dir) if File.exist?(ssh_src_dir)
      Util.make_user_owned(ssh_target_dir, user)

      mv_if_exists(File.join(ssh_target_dir, 'haproxy_id_rsa'), File.join(ssh_target_dir, 'id_rsa'), user)
      mv_if_exists(File.join(ssh_target_dir, 'haproxy_id_rsa.pub'), File.join(ssh_target_dir, 'id_rsa.pub'), user)

      Util.add_gear_env_var(user, 'OPENSHIFT_APP_SSH_KEY', File.join(ssh_target_dir, 'id_rsa'))
      Util.add_gear_env_var(user, 'OPENSHIFT_APP_SSH_PUBLIC_KEY', File.join(ssh_target_dir, 'id_rsa.pub'))
      output
    end
  end
    end
  end
end
