require 'open4'
require 'openshift-origin-node/utils/selinux'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-common/utils/path_utils'

# It would be nice if this library stayed the same across all gear migrations ever.
# But actually, it changes pretty radically. So it must be scoped to the particular migration.

module OpenShiftMigration
  module Number1
    module V2Carts
      module Util
    def self.append_to_file(f, value)
      file = File.open(f, 'a')
      begin
        file.puts ""
        file.puts value
      ensure
        file.close
      end
      return "Appended '#{value}' to '#{file}'"
    end

    def self.contains_value?(f, value)
      file = File.open(f, 'r')
      begin
        file.each {|line| return true if line.include? value}
      ensure
        file.close
      end
      false
    end

    def self.replace_in_file(file, old_value, new_value, sep=',')
      output, exitcode = execute_script("sed -i \"s#{sep}#{old_value}#{sep}#{new_value}#{sep}g\" #{file} 2>&1")
      #TODO handle exitcode
      return "Updated '#{file}' changed '#{old_value}' to '#{new_value}'.  output: #{output}  exitcode: #{exitcode}\n"
    end

    def self.gear_has_cart?(gear_home, cart_name)
      File.directory?(File.join(gear_home, cart_name))
    end

    def self.get_env_var_value(app_home, env_var_name)
      file_contents = file_to_string("#{app_home}/.env/#{env_var_name}").chomp
      eq_index = file_contents.index('=')

      return file_contents unless eq_index

      value = file_contents[(eq_index + 1)..-1]
      value = value[1..-1] if value.start_with?("'")
      value = value[0..-2] if value.end_with?("'")
      return value
    end

    def self.add_env_vars_to_typeless_translated(homedir, env_map)
      envfile = File.join(homedir, ".env", "TYPELESS_TRANSLATED_VARS")
      File.open(envfile, File::WRONLY|File::TRUNC|File::CREAT) do |file|
        env_map.each do |name, value|
          file.write "export #{name}=\"#{value}\"\n"
        end
      end
    end

    def self.append_env_vars_to_typeless_translated(homedir, env_map)
      envfile = File.join(homedir, ".env", "TYPELESS_TRANSLATED_VARS")
      File.open(envfile, 'a') do |file|
        env_map.each do |name, value|
          file.write "export #{name}=\"#{value}\"\n"
        end
      end
    end

    def self.set_env_var_value(homedir, name, value)
      envfile = File.join(homedir, ".env", name)
      File.open(envfile, File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write "#{value}"
      end
    end

    # Copy value from old env var and write to new, deleting old env var
    #   NO-OP if old env var does not exist
    #
    # @param [String] homedir OPENSHIFT_HOMEDIR for gear under operation
    # @param [String] old     Old environment variable name
    # @param [String] new     New environment variable name
    def self.cp_env_var_value(homedir, old, new)
      old_file = File.join(homedir, ".env", old)
      if File.exists?(old_file)
        self.set_env_var_value(homedir, new, self.get_env_var_value(homedir, old))
      end
    end

    # Copy value from old env var and write to new, deleting old env var
    #   NO-OP if old env var does not exist
    #
    # @param [String] user    User for gear under operation
    # @param [String] old     Old environment variable name
    # @param [String] new     New environment variable name
    def self.mv_env_var_value(user, old, new)
      old_file = File.join(user.homedir, ".env", old)
      if File.exists?(old_file)
        self.add_gear_env_var(user, new, self.get_env_var_value(user.homedir, old))
        FileUtils.rm(old_file)
      end
    end

    # Delete list of old env var
    #   NO-OP if env var does not exist
    #
    # @param [String]         homedir OPENSHIFT_HOMEDIR for gear under operation
    # @param [ArrayOf String] name    env var to be deleted
    def self.rm_env_var(homedir, *name)
      name.each { |file|
        path = File.join(homedir, ".env", file)
        FileUtils.rm_f(path) if File.exists?(path)
      }
    end

    def self.file_to_string(file_path)
      file = File.open(file_path, "r")
      str = nil
      begin
        str = file.read
      ensure
        file.close
      end
      return str
    end

    def self.execute_script(cmd)
      output = `#{cmd}`
      exitcode = $?.exitstatus
      return output, exitcode
    end

    def self.get_mcs_level(uuid)
      userinfo = Etc.getpwnam(uuid)
      uid = userinfo.uid
      setsize=1023
      tier=setsize
      ord=uid
      while ord > tier
        ord -= tier
        tier -= 1
      end
      tier = setsize - tier
      "s0:c#{tier},c#{ord + tier}"
    end

    def self.relabel_file_security_context(mcs_level, pathlist)
      %x[ restorecon -R #{pathlist.join " "} && chcon -l #{mcs_level} -R #{pathlist.join " "} ]
    end

    def self.symlink_as_user(uuid, target, link_name)
      FileUtils.ln_s(target, link_name, :force => true)
    end

    def self.remove_dir_if_empty(dirname)
      Dir.rmdir dirname if (File.directory? dirname) && (Dir.entries(dirname) - %w[ . .. ]).empty?
    end

    # Move a list of environment variables from the gear environment
    # to a cartridge environment
    def self.move_gear_env_var_to_cart(user, cartridge_name, vars, remove_gear_env=true)
      output = ''

      vars.each do |env_var_name|
        gear_env_var = File.join(user.homedir, '.env', env_var_name)

        next if !File.exists?(gear_env_var)

        value = self.get_env_var_value(user.homedir, env_var_name)

        output << "Moving env var #{env_var_name} to #{cartridge_name} env var directory\n"

        self.add_cart_env_var(user, cartridge_name, env_var_name, value)
        FileUtils.rm_f(gear_env_var) if remove_gear_env
      end

      output
    end

    def self.make_user_owned(target, user)
      mcs_label = OpenShift::Utils::SELinux.get_mcs_label(user.uid)
      PathUtils.oo_chown_R(user.uid, user.gid, target)
      OpenShift::Utils::SELinux.set_mcs_label_R(mcs_label, target)
    end

    def self.move_directory_between_carts(user,
                                          old_cartridge_name,
                                          new_cartridge_name,
                                          directories)
      output = ''

      directories.each do |directory|
        if !File.directory?(File.join(user.homedir, old_cartridge_name, directory))
          output << "Skipping #{directory} because it is not a directory\n"
          next
        end

        output << "Moving contents of #{old_cartridge_name}/#{directory} to #{new_cartridge_name}/#{directory}\n"

        target_directory = File.join(user.homedir, new_cartridge_name, directory)

        Dir.glob(File.join(user.homedir, old_cartridge_name, directory, '*')).each do |entry|
          output << " Moving #{entry}\n"
          target = File.join(target_directory, File.basename(entry))
          OpenShift::Utils.oo_spawn("/bin/mv -f #{entry} #{target}")
        end

        make_user_owned(target_directory, user)
      end

      output
    end

    def self.add_cart_env_var(user, cart, key, value)
      env_dir = File.join(user.homedir, cart, 'env')
      self.add_user_owned_env_var(user, env_dir, key, value)
    end

    def self.add_gear_env_var(user, key, value)
      env_dir = File.join(user.homedir, '.env')
      self.add_user_owned_env_var(user, env_dir, key, value)
    end

    def self.add_user_owned_env_var(user, env_dir, key, value)
      filename = File.join(env_dir, key)
      File.open(filename, File::WRONLY|File::TRUNC|File::CREAT) do |file|
        file.write value.to_s
      end

      mcs_label = OpenShift::Utils::SELinux.get_mcs_label(user.uid)
      PathUtils.oo_chown(user.uid, user.gid, filename)
      OpenShift::Utils::SELinux.set_mcs_label(mcs_label, filename)
    end
  end
    end
  end
end

