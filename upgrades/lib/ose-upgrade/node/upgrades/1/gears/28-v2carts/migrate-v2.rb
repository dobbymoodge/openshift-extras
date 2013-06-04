require 'rubygems'
require 'etc'
require 'fileutils'
require 'socket'
require 'parseconfig'
require 'pp'


require_relative 'migrate-util'
require_relative "migrate-progress"
require_relative "migrate-v2-diy-0.1"
require_relative "migrate-v2-haproxy-1.4"
require_relative "migrate-v2-jbosseap-6.0"
require_relative "migrate-v2-jbossews"
require_relative "migrate-v2-perl-5.10"
require_relative "migrate-v2-php-5.3"
require_relative "migrate-v2-python-2.6"
require_relative "migrate-v2-ruby-1.8"
require_relative "migrate-v2-ruby-1.9"
require_relative "migrate-v2-jenkins-1.4"
require_relative "migrate-v2-jenkins-client-1.4"
require_relative "migrate-v2-mysql-5.1"
require_relative "migrate-v2-postgresql-8.4"
require_relative "migrate-v2-cron-1.4"

require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'net/http'
require 'uri'

module OpenShift
  class V2MigrationCartridgeModel < V2CartridgeModel
    ##
    # In this subclass, this method is changed slightly to account for
    # V1 cartridge directories which may exist in the gear.
    def process_cartridges(cartridge_dir = nil) # : yields cartridge_path
      if cartridge_dir
        cart_dir = File.join(@user.homedir, cartridge_dir)
        yield cart_dir if File.exist?(cart_dir)
        return
      end

      Dir[PathUtils.join(@user.homedir, "*")].each do |cart_dir|
        next if cart_dir.end_with?('app-root') || cart_dir =~ /-\d/ || cart_dir.end_with?('git') ||
            (not File.directory? cart_dir)
        yield cart_dir
      end
    end

    def gear_status
      output = ''
      problem = false

      each_cartridge do |cartridge|
        cart_status = do_control('status', cartridge)

        cart_status_msg = "[OK]"
        if cart_status !~ /running|enabled|Tail of JBoss/i
          problem = true
          cart_status_msg = "[PROBLEM]"
        end

        output << "Cart status for #{cartridge.name} #{cart_status_msg}: #{cart_status}\n"
      end

      return [problem, output]
    end
  end
end

module OpenShift::Utils
  class MigrationApplicationState < ApplicationState
    def initialize(uuid, state_file = '.state')
      @uuid = uuid

      config      = OpenShift::Config.new
      @state_file = File.join(config.get("GEAR_BASE_DIR"), uuid, "app-root", "runtime", state_file)
    end
  end
end

module OpenShiftMigration
  module Number1
    module V2Carts
      PREMIGRATION_STATE = '.premigration_state'

      # Categorize cartridges to drive the correct configure order during migration
      FRAMEWORK_CARTS = %w(diy-0.1 jbosseap-6.0 jbossews-1.0 jenkins-1.4 perl-5.10 php-5.3 python-2.6 ruby-1.8 ruby-1.9)
      DB_CARTS        = %w(mysql-5.1 postgresql-8.4)
      PLUGIN_CARTS    = %w(cron-1.4 jenkins-client-1.4)

      def self.rm_exists(file)
        # We want all errors reported, except for missing file...
        FileUtils.rm(file) if File.exists?(file)
      end

      # Note: This method must be reentrant, meaning it should be able to
      # be called multiple times on the same gears.  Each time having failed
      # at any point and continue to pick up where it left off or make
      # harmless changes the 2-n times around.
      def self.migrate(params = {})

        progress = MigrationProgress.new(params[:uuid])
        exitcode = 0
        
        unless (File.exists?(params[:gear_home]) && !File.symlink?(params[:gear_home]))
          exitcode = 127
          progress.log "Application not found to migrate: #{params[:gear_home]}"
          return progress.report, exitcode
        end

        if v2_gear?(params[:gear_home])
          return "Skipping V1 -> V2 migration because gear appears to already be V2\n", 0
        end

        begin
          progress.log 'Beginning V1 -> V2 migration'
          inspect_gear_state(progress, params[:uuid], params[:gear_home])
          migrate_stop_lock(progress, params[:uuid], params[:gear_home])
          stop_gear(progress, params[:hostname], params[:uuid])
          migrate_pam_nproc_soft(progress, params[:uuid])
          cleanup_gear_env(progress, params[:gear_home])
          migrate_env_vars_to_raw(progress, params[:gear_home])
          migrate_typeless_translated_vars(progress, params[:uuid], params[:gear_home])
          relocate_uservars(progress, params[:gear_home])
          migrate_git_repo(progress, params[:uuid])

          OpenShift::Utils::Sdk.mark_new_sdk_app(params[:gear_home])
          cartridge_migrators = load_cartridge_migrators

          migrate_cartridges(progress, params[:gear_home], params[:uuid], cartridge_migrators)

          start_gear(progress, params[:hostname], params[:uuid])

          validate_gear(progress, params[:uuid], params[:gear_home])
          cleanup(progress, params[:gear_home])

        rescue OpenShift::Utils::ShellExecutionException => e
          progress.log %Q(#{e.message} stdout => \n #{e.stdout} stderr => \n #{e.stderr})
          exitcode = 1
        rescue Exception => e
          progress.log "Caught an exception during internal migration steps: #{e.message}"
          progress.log e.backtrace.join("\n")
          exitcode = 1
        end

        [progress.report, exitcode]
      end

      def self.v2_gear?(gear_home)
        migration_metadata = Dir.glob(File.join(gear_home, 'app-root', 'data', '.migration_complete*'))
        (OpenShift::Utils::Sdk.new_sdk_app?(gear_home) && migration_metadata.size == 0)
      end

      def self.inspect_gear_state(progress, uuid, gear_home)
        progress.log "Inspecting gear at #{gear_home}"

        if progress.incomplete? 'inspect_gear_state'
          app_state = File.join(gear_home, 'app-root', 'runtime', '.state')
          save_state = File.join(gear_home, 'app-root', 'runtime', PREMIGRATION_STATE)

          FileUtils.cp(app_state, save_state)

          premigration_state = OpenShift::Utils::MigrationApplicationState.new(uuid, PREMIGRATION_STATE)
          progress.log "Pre-migration state: #{premigration_state.value}"
          progress.mark_complete('inspect_gear_state')
        end
      end

      def self.migrate_stop_lock(progress, uuid, gear_home)
        if progress.incomplete? 'detect_v1_stop_lock'

          v1_carts = v1_cartridges(gear_home)

          carts_to_check = v1_carts[:framework_carts]

          if carts_to_check.empty?
            carts_to_check = v1_carts[:db_carts]
          end

          stop_lock_found = false

          progress.log "Checking for V1 stop lock in #{carts_to_check}"

          carts_to_check.each do |cart|
            next if File.symlink?(File.join(gear_home, cart))

            stop_glob = Dir.glob(File.join(gear_home, cart, 'run', 'stop_lock'))
            stop_lock_found = !stop_glob.empty?

            if stop_lock_found
              progress.log "Stop lock found: #{stop_glob.to_s}"
              break
            end
          end

          if stop_lock_found
            config = OpenShift::Config.new
            state  = OpenShift::Utils::ApplicationState.new(uuid)
            user   = OpenShift::UnixUser.from_uuid(uuid)

            progress.log 'Creating V2 stop_lock'

            cart_model = OpenShift::V2MigrationCartridgeModel.new(config, user, state)
            cart_model.create_stop_lock
          else
            progress.log 'V1 stop lock not detected'
          end

          progress.mark_complete('migrate_stop_lock')
        end
      end

      def self.stop_gear(progress, hostname, uuid)
        progress.log "Stopping gear with uuid '#{uuid}' on node '#{hostname}'"

        if progress.incomplete? 'stop_gear'
          container = OpenShift::ApplicationContainer.from_uuid(uuid)
          begin
            container.stop_gear(user_initiated: false)
          rescue Exception => e
            progress.log "Stop gear failed with an exception: #{e.message}"
          ensure
            OpenShift::UnixUser.kill_procs(container.user.uid)
          end

          progress.mark_complete('stop_gear')
        end
      end

      def self.start_gear(progress, hostname, uuid)
        progress.log "Starting gear with uuid '#{uuid}' on node '#{hostname}'"

        if progress.incomplete? 'start_gear'
          container = OpenShift::ApplicationContainer.from_uuid(uuid)

          begin
            output = container.start_gear(user_initiated: false)  
            progress.log "Start gear output: #{output}"
          rescue Exception => e
            progress.log "Start gear failed with an exception: #{e.message}"
            raise
          end

          progress.mark_complete('start_gear')
        end
      end

      def self.load_cartridge_migrators
        migrators = {}

        migrators['diy-0.1']             = Diy01Migration.new
        migrators['haproxy-1.4']         = Haproxy14Migration.new
        migrators['jbosseap-6.0']        = Jbosseap60Migration.new
        migrators['jbossews-1.0']        = JbossewsMigration.new
        migrators['perl-5.10']           = Perl510Migration.new
        migrators['php-5.3']             = Php53Migration.new
        migrators['python-2.6']          = Python26Migration.new
        migrators['ruby-1.8']            = Ruby18Migration.new
        migrators['ruby-1.9']            = Ruby19Migration.new
        migrators['jenkins-1.4']         = Jenkins14Migration.new
        migrators['jenkins-client-1.4']  = JenkinsClient14Migration.new
        migrators['mysql-5.1']           = Mysql51Migration.new
        migrators['postgresql-8.4']      = Postgresql84Migration.new
        migrators['cron-1.4']            = Cron14Migration.new

        migrators
      end

      def self.migrate_pam_nproc_soft(progress, uuid)
        if progress.incomplete? 'pam_nproc_soft'
          pamfile = "/etc/security/limits.d/84-#{uuid}.conf"
          scratch = "/etc/security/limits.d/84-#{uuid}.new"
          if File.exist?(pamfile)
            buf = File.read(pamfile)
            if buf.gsub!(/(?<=\s)hard(?=\s*nproc)/, 'soft')
              File.open(scratch, 'w') do |f|
                f.write(buf)
              end
              %x[chown --reference=#{pamfile} #{scratch}]
              %x[chmod --reference=#{pamfile} #{scratch}]
              %x[chcon --reference=#{pamfile} #{scratch}]

              # If we got here, then the file was written safely.
              %x[mv -f #{scratch} #{pamfile}]
            end
          end
          progress.mark_complete('pam_nproc_soft')
        end
      end

      def self.migrate_env_vars_to_raw(progress, gear_home)
        if progress.incomplete? 'env_vars_to_raw'
          Dir.glob(File.join(gear_home, '.env', '*')).each do |entry|
            next if File.basename(entry) == 'TYPELESS_TRANSLATED_VARS'

            content = IO.read(entry).chomp

            if content =~ /^export /
              index          = content.index('=')
              parsed_content = content[(index + 1)..-1]
              parsed_content.gsub!(/\A["']|["']\Z/, '')
              progress.log "Migrated #{File.basename(entry)} v1 value [#{content}] to raw value [#{parsed_content}]"
              IO.write(entry, parsed_content)
            end
          end

          progress.mark_complete('env_vars_to_raw')
        end
      end

      def self.migrate_typeless_translated_vars(progress, uuid, gear_home)
        if progress.incomplete? 'typeless_translated_vars'
          progress.log 'Migrating TYPELESS_TRANSLATED_VARS to discrete variables'
          user = OpenShift::UnixUser.from_uuid(uuid)
          blacklist = %w(OPENSHIFT_GEAR_CTL_SCRIPT)
          vars_file = File.join(gear_home, '.env', 'TYPELESS_TRANSLATED_VARS')

          if File.exists?(vars_file)
            env = OpenShift::Utils::Environ.for_gear(gear_home)
            content = IO.read(vars_file)

            content.each_line do |line|
              line.chomp!
              if line =~ /^export /
                index = line.index('=')
                key = line[7...index]
                value = line[(index + 1)..-1]
                value.gsub!(/\A["']|["']\Z/, '')

                if blacklist.include?(key)
                  progress.log " Skipping #{key} because it is in the blacklist"
                  next
                end

                if value[0] == '$'
                  referenced_var = value[1..-1]
                  value = env[referenced_var]

                  if value.nil?
                    progress.log " Unable to resolve $#{referenced_var}; skipping #{key}."
                    next
                  end
                end

                progress.log " Creating #{key} with value: #{value}"

                env_var_file = File.join(gear_home, '.env', key)

                IO.write(env_var_file, value)

                mcs_label = OpenShift::Utils::SELinux.get_mcs_label(uuid)
                PathUtils.oo_chown(0, user.gid, env_var_file)
                OpenShift::Utils::SELinux.set_mcs_label(mcs_label, env_var_file)
              end
            end

            FileUtils.rm_f(vars_file)
          end

          progress.mark_complete('typeless_translated_vars')
        end
      end

      def self.cleanup_gear_env(progress, gear_home)
        if progress.incomplete? 'gear_env_cleanup'
          FileUtils.rm_rf(File.join(gear_home, '.env', 'USER_VARS'))
          FileUtils.rm_rf(File.join(gear_home, '.env', 'TRANSLATE_GEAR_VARS'))
          progress.mark_complete('gear_env_cleanup')
        end
      end

      def self.migrate_git_repo(progress, uuid)
        user = OpenShift::UnixUser.from_uuid(uuid)
        repo = OpenShift::ApplicationRepository.new(user)

        v1_scaled_bare_repo = File.join(user.homedir, "git", "#{user.uuid}.git")
        if Dir.exists?(v1_scaled_bare_repo)
          progress.log "Migrating V1 scaled bare repo from #{v1_scaled_bare_repo} to #{repo.path}"
          FileUtils.mv v1_scaled_bare_repo, repo.path, :force => true
        end

        if repo.exists? && progress.incomplete?("reconfigure_git_repo")
          repo.configure
          progress.mark_complete('reconfigure_git_repo')
        end
      end

      def self.relocate_uservars(progress, gear_home)
        if progress.incomplete? 'relocate_uservars'
          blacklist = %w(PYTHON_EGG_CACHE)

          uservars_dir = File.join(gear_home, '.env', '.uservars')

          Dir.glob(File.join(uservars_dir, '*')).each do |entry|
            name = File.basename(entry)

            if blacklist.include?(name)
              FileUtils.rm_f(entry)
              next
            end

            name =~ /OPENSHIFT_([^_]+)/
            cart = $1.downcase

            namespaced_dir = File.join(gear_home, '.env', cart)
            FileUtils.mkpath(namespaced_dir)

            FileUtils.mv(entry, File.join(namespaced_dir, name))
          end

          FileUtils.rm_rf(uservars_dir)

          progress.mark_complete('relocate_uservars')
        end
      end

      def self.migrate_cartridges(progress, gear_home, uuid, cartridge_migrators)
        carts_to_migrate = v1_cartridges(gear_home, progress)

        progress.log "Carts to migrate: #{carts_to_migrate}"

        carts_to_migrate.values.each do |cartridge_name|
          tokens = cartridge_name.split('-')
          version = tokens.pop
          name = tokens.join('-')
          progress.log "Migrating cartridge #{name}"
          progress.log migrate_cartridge(progress, name, version, uuid, cartridge_migrators)
        end
      end

      def self.v1_cartridges(gear_home, progress = nil)
        carts = Hash.new { |h, k| h[k] = [] }

        def carts.values
          # Establish the correct configure order for the migrated carts
          self[:framework_carts] + self[:plugin_carts] + self[:db_carts] + self[:leftover_carts]
        end

        Dir.glob(File.join(gear_home, '*-*')).each do |entry|
          # Account for app-root and V2 carts matching the glob which already may be installed
          next if entry.end_with?('app-root') || entry.end_with?('jenkins-client') || entry.end_with?('mms-agent') || !File.directory?(entry)

          cart_name = File.basename(entry)

          if FRAMEWORK_CARTS.include?(cart_name)
            carts[:framework_carts] << cart_name
          elsif PLUGIN_CARTS.include?(cart_name)
            carts[:plugin_carts] << cart_name
          elsif DB_CARTS.include?(cart_name)
            carts[:db_carts] << cart_name
          else
            # should be haproxy...
            carts[:leftover_carts] << cart_name
          end
        end

        carts
      end

      def self.migrate_cartridge(progress, name, version, uuid, cartridge_migrators)
        config = OpenShift::Config.new
        state  = OpenShift::Utils::ApplicationState.new(uuid)
        user   = OpenShift::UnixUser.from_uuid(uuid)

        cart_model = OpenShift::V2MigrationCartridgeModel.new(config, user, state)
        cartridge  = OpenShift::CartridgeRepository.instance.select(name, version)

        OpenShift::Utils::Cgroups.with_no_cpu_limits(uuid) do
          if progress.incomplete? "#{name}_create_directory"
            cart_model.create_cartridge_directory(cartridge, version)
            progress.mark_complete("#{name}_create_directory")
          end

          Dir.chdir(user.homedir) do
            cart_model.unlock_gear(cartridge) do |c|
              if progress.incomplete? "#{name}_setup"
                progress.log cart_model.cartridge_action(c, 'setup', version, true)
                progress.mark_complete("#{name}_setup")
              end

              if progress.incomplete? "#{name}_erb"
                cart_model.process_erb_templates(c)
                progress.mark_complete("#{name}_erb")
              end

              env = OpenShift::Utils::Environ.for_gear(user.homedir, name)

              if progress.incomplete? "#{name}_hook"
                cartridge_migrator = cartridge_migrators["#{name}-#{version}"]
                if cartridge_migrator
                  progress.log cartridge_migrator.post_process(user, progress, env)
                else
                  progress.log "Unable to find migrator for #{cartridge}"
                end
                progress.mark_complete("#{name}_hook")
              end

              if progress.incomplete? "#{name}_ownership"
                target = File.join(user.homedir, c.directory)
                cart_model.secure_cartridge(c.short_name, user.uid, user.gid, target)
                progress.mark_complete("#{name}_ownership")
              end
            end
          end

          if progress.incomplete? "#{name}_connect_frontend"
            cart_model.connect_frontend(cartridge)
            progress.mark_complete("#{name}_connect_frontend")
          end
        end

        FileUtils.rm_rf(File.join(user.homedir, "#{name}-#{version}"))

        FileUtils.ln_s(File.join(user.homedir, name), File.join(user.homedir, "#{name}-#{version}"))
      end

      def self.validate_gear(progress, uuid, gear_home)
        progress.log "Validating gear #{uuid} post-migration"

        if progress.incomplete? 'validate_gear'
          premigration_state = OpenShift::Utils::MigrationApplicationState.new(uuid, PREMIGRATION_STATE)

          progress.log "Pre-migration state: #{premigration_state.value}"

          if premigration_state.value != 'stopped' && premigration_state.value != 'idle'
            config = OpenShift::Config.new
            state  = OpenShift::Utils::ApplicationState.new(uuid)
            user   = OpenShift::UnixUser.from_uuid(uuid)

            cart_model = OpenShift::V2MigrationCartridgeModel.new(config, user, state)

            # only validate via http query on the head gear
            if cart_model.primary_cartridge && (user.uuid == user.application_uuid)
              env = OpenShift::Utils::Environ.for_gear(gear_home)

              dns = env['OPENSHIFT_GEAR_DNS']
              uri = URI.parse("http://#{dns}")

              num_tries = 1
              while true do
                http = Net::HTTP.new(uri.host, uri.port)
                request = Net::HTTP::Get.new(uri.request_uri)
                response = http.request(request)
                # Give the app a chance to start fully
                if response.code == '503' && num_tries < 5
                  sleep num_tries
                else
                  break
                end
                num_tries += 1
              end

              progress.log "Post-migration response code: #{response.code}"
            end

            problem, status = cart_model.gear_status

            if problem
              progress.log "Leaving migration metadata in place due to problem detected with gear status:\n#{status}"
              return
            end
          end

          progress.mark_complete('validate_gear')
        end
      end

      def self.cleanup(progress, gear_home)
        if progress.complete? 'validate_gear'
          progress.log 'Cleaning up after migration'
          FileUtils.rm_f(File.join(gear_home, 'app-root', 'runtime', PREMIGRATION_STATE))
          progress.done
        end
      end

      ## These will replace their un-versioned counterparts in version 2.0.29
      #######################################################################
      def self.migrate_v2v2(uuid, namespace, version, hostname)
        #unless version == 'future version here'
        #  return "Invalid version: #{version}\n", 255
        #end

        start_time = (Time.now.to_f * 1000).to_i

        gear_home = "/var/lib/openshift/#{uuid}"
        unless File.directory?(gear_home) && !File.symlink?(gear_home)
          return "Application not found to migrate: #{gear_home}\n", 127
        end

        gear_env = OpenShift::Utils::Environ.for_gear(gear_home)

        unless gear_env.key?('OPENSHIFT_GEAR_NAME') && gear_env.key?('OPENSHIFT_APP_NAME')
          return "***acceptable_error_env_vars_not_found={\"gear_uuid\":\"#{uuid}\"}***\n", 0
        end

        exitcode = 0
        progress = MigrationProgress.new(uuid)

        begin
          progress.log "Beginning #{version} migration for #{uuid}"
          inspect_gear_state(progress, uuid, gear_home)

          migrate_cartridges_v2v2(progress, gear_home, gear_env, uuid, hostname)

          validate_gear(progress, uuid, gear_home)
          cleanup(progress, gear_home)

          total_time = (Time.now.to_f * 1000).to_i - start_time
          progress.log "***time_migrate_on_node_measured_from_node=#{total_time}***"
        rescue => e
          progress.log "Caught an exception during internal migration steps: #{e.message}"
          progress.log e.backtrace.join("\n")
          exitcode = 1
        end

        [progress.report, exitcode]
      end

      def self.migrate_cartridges_v2v2(progress, gear_home, gear_env, uuid, hostname)
        progress.log "Migrating gear at #{gear_home}"

        config               = OpenShift::Config.new
        state                = OpenShift::Utils::ApplicationState.new(uuid)
        user                 = OpenShift::UnixUser.from_uuid(uuid)
        cartridge_model      = OpenShift::V2MigrationCartridgeModel.new(config, user, state)
        cartridge_repository = OpenShift::CartridgeRepository.instance
        restart_required     = false

        OpenShift::Utils::Cgroups.with_no_cpu_limits(uuid) do
          Dir.chdir(user.homedir) do
            cartridge_model.each_cartridge do |manifest|
              cartridge_path                           = File.join(gear_home, manifest.directory)
              ident_path                               = Dir.glob(File.join(cartridge_path, 'env', 'OPENSHIFT_*_IDENT')).first
              ident                                    = IO.read(ident_path)
              vendor, name, version, cartridge_version = OpenShift::Runtime::Manifest.parse_ident(ident)

              unless vendor == 'redhat'
                progress.log "No migration available for cartridge #{ident}, #{vendor} not supported."
                next
              end

              next_manifest = cartridge_repository.select(name, version)
              unless next_manifest
                progress.log "No migration available for cartridge #{ident}, found in repository."
                next
              end

              unless next_manifest.versions.include?(version)
                progress.log "No migration available for cartridge #{ident}, version #{version} not in #{next_manifest.versions}"
                next
              end

              if next_manifest.cartridge_version == cartridge_version
                progress.log "No migration required for cartridge #{ident}, already at latest version #{cartridge_version}."
                next
              end

              if next_manifest.compatible_versions.include?(cartridge_version)
                progress.log "Compatible migration of cartridge #{ident}"
                compatible_migration(progress, cartridge_model, next_manifest, version, cartridge_path, user)
              else
                stop_gear(progress, hostname, uuid) unless restart_required
                restart_required = true

                progress.log "Incompatible migration of cartridge #{ident}"
                incompatible_migration(progress, cartridge_model, next_manifest, version, cartridge_path, user)
              end

              next_ident = OpenShift::Runtime::Manifest.build_ident(manifest.cartridge_vendor,
                                                                    manifest.name,
                                                                    manifest.version,
                                                                    next_manifest.cartridge_version)
              IO.write(ident_path, next_ident, 0, mode: 'w', perms: 0666)
              progress.mark_complete("#{manifest.name}_update_ident")
            end
          end
        end

        if restart_required
          restart_start_time = (Time.now.to_f * 1000).to_i
          start_gear(progress, hostname, uuid)
          restart_time = (Time.now.to_f * 1000).to_i - restart_start_time
          progress.log "***time_restart=#{restart_time}***"
        end
      end

      # Simple change that does not require the gear to be restarted
      def self.compatible_migration(progress, cart_model, next_manifest, version, target, user)
        OpenShift::CartridgeRepository.overlay_cartridge(next_manifest, target)

        # No ERB's are rendered for fast migrations
        FileUtils.rm_f cart_model.processed_templates(next_manifest)
        progress.mark_complete("#{name}_remove_erb")

        cart_model.unlock_gear(next_manifest) do |m|
          cart_model.secure_cartridge(next_manifest.short_name, user.uid, user.gid, target)
        end
      end

      def self.incompatible_migration(progress, cart_model, next_manifest, version, target, user)
        OpenShift::CartridgeRepository.overlay_cartridge(next_manifest, target)
        cart_model.secure_cartridge(next_manifest.short_name, user.uid, user.gid, target)

        cart_model.unlock_gear(next_manifest) do |m|
          if progress.incomplete? "#{name}_setup"
            progress.log cart_model.cartridge_action(m, 'setup', version, true)
            progress.mark_complete("#{name}_setup")
          end

          if progress.incomplete? "#{name}_erb"
            cart_model.process_erb_templates(m)
            progress.mark_complete("#{name}_erb")
          end

        end

        if progress.incomplete? "#{name}_connect_frontend"
          cart_model.connect_frontend(next_manifest)
          progress.mark_complete("#{name}_connect_frontend")
        end
      end
    end
  end
end
