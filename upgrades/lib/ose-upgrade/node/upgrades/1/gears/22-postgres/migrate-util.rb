require 'open4'

module OpenShiftMigration
  module Number1
    module Postgres
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
        file.write "export #{name}='#{value}'"
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
    # @param [String] homedir OPENSHIFT_HOMEDIR for gear under operation
    # @param [String] old     Old environment variable name
    # @param [String] new     New environment variable name
    def self.mv_env_var_value(homedir, old, new)
      old_file = File.join(homedir, ".env", old)
      if File.exists?(old_file)
        self.set_env_var_value(homedir, new, self.get_env_var_value(homedir, old))
        FileUtils.rm(old_file)
      end
    end

    # Delete list of old env var
    #   NO-OP if env var does not exist
    #
    # @param [String]         homedir OPENSHIFT_HOMEDIR for gear under operation
    # @param [ArrayOf String] name    env var to be deleted
    def self.rm_env_var_value(homedir, *name)
      name.each { |file|
        path = File.join(homedir, ".env", file)
        FileUtils.rm(path) if File.exists?(path)
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

  end
end
  end
end
