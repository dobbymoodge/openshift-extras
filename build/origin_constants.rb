require 'fileutils'
require 'rubygems'
#
# Global definitions
#

OPTIONS = {
  "fedora" => {
    "amis"            => {"us-east-1" =>"ami-6145cc08"},
    "devenv_name"     => "oso-fedora",
    "ssh_user"        => "ec2-user",    
    "ignore_packages" => [
      'openshift-origin-util-scl', 
      'rubygem-openshift-origin-auth-kerberos', 
      'openshift-origin-cartridge-postgresql-8.4',
      "openshift-origin-cartridge-ruby-1.8",
      "openshift-origin-cartridge-ruby-1.9-scl",
      'openshift-origin-cartridge-perl-5.10',
      'openshift-origin-cartridge-php-5.3',
      'openshift-origin-cartridge-python-2.6',
      'openshift-origin-cartridge-phpmyadmin-3.4',

      'openshift-origin-cartridge-jbosseap-6.0', 
      'openshift-origin-cartridge-jbossas-7',
      "openshift-origin-cartridge-switchyard-0.6",
      'openshift-origin-cartridge-jbossas-7',
      'openshift-origin-cartridge-switchyard-0.6',
      'openshift-origin-cartridge-jbossews-1.0', 
      'openshift-origin-cartridge-jbossews-2.0',
    ],
    "cucumber_options"        => '--strict -f progress -f junit --out /tmp/rhc/cucumber_results -t ~@rhel-only -t ~@jboss',
    "broker_cucumber_options" => '--strict -f html --out /tmp/rhc/broker_cucumber.html -f progress  -t ~@rhel-only -t ~@jboss',
  },
  "rhel"   => {
    "amis"            => {"us-east-1" =>"ami-cc5af9a5"},
    "devenv_name"     => "enterprise",
    "ssh_user"        => "root",
    "ignore_packages" => [
      'rubygem-openshift-origin-auth-kerberos',
      'openshift-origin-util',
      "openshift-origin-cartridge-ruby-1.9",
      'openshift-origin-cartridge-perl-5.16',
      'openshift-origin-cartridge-php-5.4',
      'openshift-origin-cartridge-phpmyadmin-3.5',
      'openshift-origin-cartridge-postgresql-9.2',

      'openshift-origin-cartridge-jbosseap-6.0', 
      'openshift-origin-cartridge-jbossas-7',
      "openshift-origin-cartridge-switchyard-0.6",
      'openshift-origin-cartridge-jbossas-7',
      'openshift-origin-cartridge-switchyard-0.6',
      'openshift-origin-cartridge-jbossews-1.0', 
      'openshift-origin-cartridge-jbossews-2.0',
    ],
    "cucumber_options"        => '--strict -f progress -f junit --out /tmp/rhc/cucumber_results -t ~@fedora-only -t ~@jboss',
    "broker_cucumber_options" => '--strict -f html --out /tmp/rhc/broker_cucumber.html -f progress  -t ~@fedora-only -t ~@jboss',    
  },
}

TYPE = "m1.large"
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
                 'puppet-openshift_origin' => ['../puppet-openshift_origin'],
                 'openshift-extras' => ['../openshift-extras']}
OPENSHIFT_ARCHIVE_DIR_MAP = {'rhc' => 'rhc/'}
SIBLING_REPOS_GIT_URL = {'enterprise-server' => 'git@github.com:openshift/enterprise-server.git',
                        'enterprise-rhc' => 'git@github.com:openshift/enterprise-rhc.git',
                        'enterprise' => 'git@github.com:openshift/enterprise.git',
                        'enterprise-dev-tools' => 'git@github.com:openshift/enterprise-dev-tools.git',
                        'puppet-openshift_origin' => 'https://github.com/openshift/puppet-openshift_origin.git',
                        'openshift-extras' => 'git@github.com:openshift/openshift-extras.git'}

DEV_TOOLS_REPO = 'enterprise-dev-tools'
DEV_TOOLS_EXT_REPO = 'enterprise'
ADDTL_SIBLING_REPOS = SIBLING_REPOS_GIT_URL.keys - [DEV_TOOLS_REPO]
ACCEPT_DEVENV_SCRIPT = 'true'
$amz_options = {:key_name => KEY_PAIR, :instance_type => TYPE}

def guess_os(base_os=nil)
  return base_os unless base_os.nil?
  if File.exist?("/etc/fedora-release")
    return "fedora"
  elsif File.exist?("/etc/redhat-release")
    data = File.read("/etc/redhat-release")
    if data.match(/centos/)
      return "centos"
    else
      return "rhel"
    end
  end
end

def def_constants(base_os="rhel")
  Object.const_set(:AMI, OPTIONS[base_os]["amis"]) unless Object.const_defined?(:AMI)
  Object.const_set(:SSH_USER, OPTIONS[base_os]["ssh_user"]) unless Object.const_defined?(:SSH_USER)  
  Object.const_set(:DEVENV_NAME, OPTIONS[base_os]["devenv_name"]) unless Object.const_defined?(:DEVENV_NAME)
  Object.const_set(:IGNORE_PACKAGES, OPTIONS[base_os]["ignore_packages"]) unless Object.const_defined?(:IGNORE_PACKAGES)
  Object.const_set(:CUCUMBER_OPTIONS, OPTIONS[base_os]["cucumber_options"]) unless Object.const_defined?(:CUCUMBER_OPTIONS)
  Object.const_set(:BROKER_CUCUMBER_OPTIONS, OPTIONS[base_os]["broker_cucumber_options"]) unless Object.const_defined?(:BROKER_CUCUMBER_OPTIONS)
  Object.const_set(:BASE_OS, base_os) unless Object.const_defined?(:BASE_OS)
end
