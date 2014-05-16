require 'fileutils'
require 'rubygems'
#
# Global definitions
#

OPTIONS = {
  "rhel"   => {
    "amis"            => {"us-east-1" =>"ami-15c59f7c"},
    "devenv_name"     => "enterprise",
    "ssh_user"        => "ec2-user",
    "ignore_packages" => [
      'avahi-cname-manager',
      'openshift-origin-cartridge-10gen-mms-agent',
      'openshift-origin-cartridge-abstract',
      'openshift-origin-cartridge-jbossas',
      'openshift-origin-cartridge-mariadb',
      'openshift-origin-cartridge-mongodb',
      'openshift-origin-cartridge-phpmyadmin',
      'openshift-origin-cartridge-switchyard',
      'openshift-origin-util',
      'rubygem-openshift-origin-auth-kerberos',
      'rubygem-openshift-origin-auth-mongo',
      'rubygem-openshift-origin-container-libvirt',
      'rubygem-openshift-origin-dns-avahi',
      'rubygem-openshift-origin-dns-bind',
      'rubygem-openshift-origin-dns-route53',
      'rubygem-openshift-origin-frontend-apache-vhost',
      'openshift-origin-port-proxy',
    ],
    "cucumber_options"        => '--strict -f progress -f junit --out /tmp/rhc/cucumber_results -t ~@fedora-only -t ~@not-enterprise',
    "broker_cucumber_options" => '--strict -f html --out /tmp/rhc/broker_cucumber.html -f progress  -t ~@fedora-only -t ~@not-enterprise',
  },
}

TYPE = "m3.large"
ZONE = 'us-east-1d'
VERIFIER_REGEXS = {}
TERMINATE_REGEX = /terminate/
VERIFIED_TAG = "qe-ready"

# Specify the source location of the SSH key
# This will be used if the key is not found at the location specified by "RSA"
KEY_PAIR = "libra"
RSA = File.expand_path("~/.ssh/devenv.pem")
RSA_SOURCE = ""

SAUCE_USER = ""
SAUCE_SECRET = ""
SAUCE_OS = ""
SAUCE_BROWSER = ""
SAUCE_BROWSER_VERSION = ""
CAN_SSH_TIMEOUT=90
SLEEP_AFTER_LAUNCH=60

SIBLING_REPOS = {'enterprise-server' => ['../enterprise-server'],
                 'enterprise-rhc' => ['../enterprise-rhc'],
                 'enterprise' => ["../#{File.basename(FileUtils.pwd)}"],
                 'enterprise-dev-tools' => ['../enterprise-dev-tools'],
                 'puppet-openshift_enterprise' => ['../puppet-openshift_enterprise'],
                 'openshift-extras' => ['../openshift-extras']}
OPENSHIFT_ARCHIVE_DIR_MAP = {'enterprise-rhc' => 'rhc/'}
SIBLING_REPOS_GIT_URL = {'enterprise-server' => 'git@github.com:openshift/enterprise-server.git',
                        'enterprise-rhc' => 'git@github.com:openshift/enterprise-rhc.git',
                        'enterprise' => 'git@github.com:openshift/enterprise.git',
                        'enterprise-dev-tools' => 'git@github.com:openshift/enterprise-dev-tools.git',
                        'puppet-openshift_enterprise' => 'git@github.com:openshift/puppet-openshift_enterprise.git',
                        'openshift-extras' => 'git@github.com:openshift/openshift-extras.git'}

DEV_TOOLS_REPO = 'enterprise-dev-tools'
DEV_TOOLS_EXT_REPO = 'enterprise'
ADDTL_SIBLING_REPOS = SIBLING_REPOS_GIT_URL.keys - [DEV_TOOLS_REPO, DEV_TOOLS_EXT_REPO]
ACCEPT_DEVENV_SCRIPT = 'true'
$amz_options = {:key_name => KEY_PAIR, :instance_type => TYPE}

def guess_os(base_os=nil)
  return "rhel"
end

def def_constants(base_os="rhel")
  Object.const_set(:AMI, OPTIONS[base_os]["amis"]) unless Object.const_defined?(:AMI)
  Object.const_set(:SSH_USER, OPTIONS[base_os]["ssh_user"]) unless Object.const_defined?(:SSH_USER)  
  Object.const_set(:DEVENV_NAME, OPTIONS[base_os]["devenv_name"]) unless Object.const_defined?(:DEVENV_NAME)
  Object.const_set(:IGNORE_PACKAGES, OPTIONS[base_os]["ignore_packages"]) unless Object.const_defined?(:IGNORE_PACKAGES)
  Object.const_set(:CUCUMBER_OPTIONS, OPTIONS[base_os]["cucumber_options"]) unless Object.const_defined?(:CUCUMBER_OPTIONS)
  Object.const_set(:BROKER_CUCUMBER_OPTIONS, OPTIONS[base_os]["broker_cucumber_options"]) unless Object.const_defined?(:BROKER_CUCUMBER_OPTIONS)
  Object.const_set(:BASE_OS, base_os) unless Object.const_defined?(:BASE_OS)

  scl_root = ""
  scl_prefix = ""
  if(BASE_OS == "rhel" or BASE_OS == "centos")
    scl_root = "/opt/rh/ruby193/root"
    scl_prefiex = "ruby193-"
  end
  Object.const_set(:SCL_ROOT, scl_root) unless Object.const_defined?(:SCL_ROOT)
  Object.const_set(:SCL_PREFIX, scl_prefix) unless Object.const_defined?(:SCL_PREFIX)
end
