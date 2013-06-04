require 'rubygems'
require 'fileutils'
require_relative  "./migrate-util"

module OpenShiftMigration
  module Number1
    module Postgres

  # Note: This method must be reentrant.  Meaning it should be able to
  # be called multiple times on the same gears.  Each time having failed
  # at any point and continue to pick up where it left off or make
  # harmless changes the 2-n times around.
  def self.migrate(params = {})

    output = ''
    exitcode = 0

    unless (File.exists?(params[:gear_home]) && !File.symlink?(params[:gear_home]))
      exitcode = 127
      output += "Application not found to migrate: #{params[:gear_home]}\n"
      return output, exitcode
    end

    cart_dir = File.join(params[:gear_home], "postgresql-8.4")
    if File.exists?(cart_dir) && File.directory?(cart_dir)
      socket_value = Util.get_env_var_value(params[:gear_home], "OPENSHIFT_POSTGRESQL_DB_SOCKET").to_s

      if (socket_value =~ /socket.+$/ )
        output += "OPENSHIFT_POSTGRESQL_DB_SOCKET: #{socket_value}\n"
        socket_value.gsub!(/socket.+$/, "socket")
        output += "Translating OPENSHIFT_POSTGRESQL_DB_SOCKET: #{socket_value}\n"
        Util.set_env_var_value(params[:gear_home], "OPENSHIFT_POSTGRESQL_DB_SOCKET", socket_value)
      end

      Util.replace_in_file("#{cart_dir}/data/pg_hba.conf", "ident$", "md5")
      Util.replace_in_file("#{cart_dir}/data/postgresql.conf", "unix_socket_directory = '/tmp'", "unix_socket_directory = '#{cart_dir}/socket'")
    end
    return output, exitcode
  end


    end
  end
end
