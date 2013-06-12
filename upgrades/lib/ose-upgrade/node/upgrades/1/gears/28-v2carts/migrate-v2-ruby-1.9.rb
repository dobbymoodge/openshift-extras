require 'fileutils'
module OpenShiftMigration
  module Number1
    module V2Carts

  class Ruby19Migration
  	RUBY_VERSION='1.9'
    def post_process(user, progress, env)
      output = "applying ruby-#{RUBY_VERSION} migration post-process\n"

      ruby_dir = File.join(user.homedir, 'ruby')

      Util.rm_env_var(user.homedir, 'OPENSHIFT_RUBY_LOG_DIR')
      Util.rm_env_var(user.homedir, 'LD_LIBRARY_PATH')
      Util.rm_env_var(user.homedir, 'MANPATH')

      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_IP', 'OPENSHIFT_RUBY_IP')
      Util.cp_env_var_value(user.homedir, 'OPENSHIFT_INTERNAL_PORT', 'OPENSHIFT_RUBY_PORT')

      cart_dir = File.join(user.homedir, 'ruby')
      cart_env = File.join(cart_dir, 'env')

      template_dir = File.join(ruby_dir, 'template')

      FileUtils.rm_rf(template_dir) if Dir.exists?(template_dir)

      FileUtils.mkdir_p template_dir

      Dir.chdir File.join(ruby_dir, 'template') do
      	FileUtils.cp_r File.join(ruby_dir, 'versions', RUBY_VERSION, 'template'), ruby_dir, :remove_destination => true
      end

     	Util.add_cart_env_var(user, 'ruby', 'OPENSHIFT_RUBY_VERSION', RUBY_VERSION)

			Util.make_user_owned(cart_env, user)

      FileUtils.ln_sf '/usr/lib64/httpd/modules', File.join(ruby_dir, 'modules')
      FileUtils.ln_sf '/etc/httpd/conf/magic', File.join(ruby_dir, 'etc', 'magic')

      output
    end
  end
    end
  end
end
