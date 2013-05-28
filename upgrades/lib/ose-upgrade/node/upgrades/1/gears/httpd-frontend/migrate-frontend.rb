# ensure we can run this either from IRB/tests or via mcollective.
# require all dependencies for the former case even if unnecessary for the latter.
require 'rubygems'
require 'etc'
require 'fileutils'
require 'socket'
require 'parseconfig'
require 'pp'
require_relative 'migrate-util'

require 'openshift-origin-node'
require 'openshift-origin-common'

module OpenShiftMigration
  module Number1
    module FrontEnd

    # Migrate the Frontend Connection for a single gear
      def self.migrate(params = {})
        o, r = FrontendHttpServerMigration.migrate(params[:uuid], params[:gear_name], params[:namespace])
        o << "ERROR: Failed to migrate frontend for #{params[:uuid]}\n" if r !=0
        return o, r
      end
    end


    module FrontendHttpServerMigration

      def self.migrate(container_uuid, container_name, namespace)
        output = ""

        config = OpenShift::Config.new

        # Consider getting these from configuration
        http_conf_dir = config.get("OPENSHIFT_HTTP_CONF_DIR")
        libra_home = config.get("GEAR_BASE_DIR")

        gear_home = File.join(libra_home, container_uuid)

        token = "#{container_uuid}_#{namespace}_#{container_name}"
        cfg_dir = File.join(http_conf_dir, token)
        cfg_file = File.join(http_conf_dir, token + ".conf")
        routes_file = File.join(cfg_dir,"routes.json")

        if File.exists?(cfg_file)
          begin

            # Create the front-end
            frontend = OpenShift::FrontendHttpServer.new(container_uuid, container_name, namespace)
            frontend.create

            # Idle
            if File.exists?(File.join(cfg_dir, "0000000000000_disabled.conf"))
              frontend.idle
            end

            # Its madness trying to parse the collection of Alias,
            # ProxyPass and RewriteRule stanzas.  Re-run the cartridge
            # deploy-httpd-proxy hooks.  The proper order appears to be:
            # 1. Framework + Embedded
            # 3. HAProxy  (can overwrite anything above)
            connections = []
            Dir.glob(File.join(gear_home, '*')).map { |d| File.basename(d) }.sort { |a,b|
              r = a<=>b
              if r !=0
                if a.start_with?("haproxy-")
                  r = 1
                elsif b.start_with?("haproxy-")
                  r = -1
                end
              end
              r
            }.each { |cart|
              meth = "proxy_" + cart.gsub('-','_').gsub('.','_')
              if self.respond_to?(meth)
                connections << self.send(meth, gear_home).flatten
              end
            }
            frontend.connect(connections.flatten)

            # Aliases, have to be done after paths are added.
            Dir.glob(File.join(cfg_dir, "server_alias-*.conf")).each do |fn|
              server_alias = fn.sub(/^.*\/server_alias-(.*)\.conf$/, '\\1')
              begin
                frontend.add_alias(server_alias)
              rescue OpenShift::FrontendHttpServerNameException
                output << "WARNING: Alias was invalid and cannot be added: #{server_alias} #{container_uuid}"
              end
            end


            # Disable the old config, will be deleted and Apache
            # restarted later
            File.rename(cfg_file, cfg_file + ".migrated")
            File.rename(cfg_dir, cfg_dir + ".migrated")

          rescue => e
            output << "ERROR: Problem migrating #{container_uuid}: #{e.inspect}\n"
            output << "#{e.backtrace}\n"
            return output, 127
          end
        end

        return output, 0
      end

      #
      # Replace calling out to hooks for speed.  If the hooks are
      # updated, then this must be updated.
      #
      def self.health_file(cartridge_type="abstract")
        config = OpenShift::Config.new
        cartridge_base_path = config.get("CARTRIDGE_BASE_PATH")
        hf = "#{cartridge_base_path}/#{cartridge_type}/info/configuration/health.html"
        if File.exists?(hf)
          return ["/health", hf, { "file" => 1 } ]
        else
          return ["/health", "#{cartridge_base_path}/abstract/info/configuration/health.html", { "file" => 1 } ]
        end
      end

      def self.abstract(gear_home, ip_var="OPENSHIFT_INTERNAL_IP")
        ip = Util.get_env_var_value(gear_home, ip_var)
        ["", "#{ip}:8080", { "websocket" => 1 }]
      end

      def self.proxy_diy_0_1(gear_home)
        [self.abstract(gear_home),
         self.health_file("diy-0.1")]
      end

      def self.proxy_haproxy_1_4(gear_home)
        ip  = Util.get_env_var_value(gear_home, "OPENSHIFT_HAPROXY_INTERNAL_IP")
        ip2 = Util.get_env_var_value(gear_home, "OPENSHIFT_HAPROXY_STATUS_IP")
        [ ["", "#{ip}:8080", { "websocket" => 1, "connections" => -1 }],
          self.health_file("haproxy-1.4"),
          ["/haproxy-status", "#{ip2}:8080/", {}] ]
      end

      def self.proxy_jbossews_1_0(gear_home)
        [self.abstract(gear_home),
         self.health_file("jbossews-1.0")]
      end

      def self.proxy_jbossews_2_0(gear_home)
        [self.abstract(gear_home),
         self.health_file("jbossews-2.0")]
      end

      def self.proxy_jenkins_1_4(gear_home)
        [self.abstract(gear_home),
         self.health_file("jenkins-1.4")]
      end

      def self.proxy_phpmyadmin_3_4(gear_home)
        ip = Util.get_env_var_value(gear_home, "OPENSHIFT_PHPMYADMIN_IP")
        [["/phpmyadmin", "#{ip}:8080/phpmyadmin", {}]]
      end

      def self.proxy_metrics_0_1(gear_home)
        ip = Util.get_env_var_value(gear_home, "OPENSHIFT_METRICS_IP")
        [["/metrics", "#{ip}:8080/metrics", {}]]
      end

      def self.proxy_rockmongo_1_1(gear_home)
        ip = Util.get_env_var_value(gear_home, "OPENSHIFT_ROCKMONGO_IP")
        [["/rockmongo", "#{ip}:8080/rockmongo", {}]]
      end

      def self.proxy_zend_5_6(gear_home)
        ip = Util.get_env_var_value(gear_home, "OPENSHIFT_INTERNAL_IP")
        [ [ "", "#{ip}:8080", {} ],
          [ "/ZendServer", "#{ip}:16081/ZendServer", {}] ]
      end

      def self.proxy_nodejs_0_6(gear_home)
        [self.abstract(gear_home),
         self.health_file("nodejs-0.6")]
      end

      def self.proxy_ruby_1_9(gear_home)
        [self.abstract(gear_home),
         self.health_file("ruby-1.9")]
      end

      def self.proxy_python_3_3(gear_home)
        [self.abstract(gear_home),
         self.health_file("python-3.3")]
      end

      def self.proxy_jbossas_7(gear_home)
        [self.abstract( gear_home),
         self.health_file("jbossas-7")]
      end

      def self.proxy_python_2_6(gear_home)
        [self.abstract(gear_home),
         self.health_file("python-2.6")]
      end

      def self.proxy_ruby_1_8(gear_home)
        [self.abstract(gear_home),
         self.health_file("ruby-1.8")]
      end

      def self.proxy_python_2_7(gear_home)
        [self.abstract( gear_home),
         self.health_file("python-2.7")]
      end

      def self.proxy_jbosseap_6_0(gear_home)
        [self.abstract( gear_home),
         self.health_file("jbosseap-6.0")]
      end

      def self.proxy_php_5_3(gear_home)
        [self.abstract( gear_home),
         self.health_file("php-5.3")]
      end

      def self.proxy_perl_5_10(gear_home)
        [self.abstract( gear_home),
         self.health_file("perl-5.10")]
      end

    end
  end
end
