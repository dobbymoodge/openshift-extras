# Global definitions
AMI = {"us-east-1" => "ami-938c5dfa"}
TYPE = "m1.large"
KEY_PAIR = "libra"
ZONE = 'us-east-1d'

DEVENV_NAME = 'devenv'

IMAGES = {DEVENV_NAME => {:branches => ['stage']},
          'enterprise' => {:branches => ['enterprise-1.2']},
          'oso-fedora' => {:branches => []}}

DEVENV_AMI_WILDCARDS = {}
IMAGES.each do |image, opts|
  keep = opts[:keep] ? opts[:keep] : 2
  DEVENV_AMI_WILDCARDS["#{image}_*"] = {:keep => keep, :regex => /^(#{image})_(\d+)/}
  DEVENV_AMI_WILDCARDS["#{image}-base_*"] = {:keep => keep, :regex => /^(#{image}-base)_(\d+)/}
  if opts[:branches]
    opts[:branches].each do |branch|
      DEVENV_AMI_WILDCARDS["#{image}-#{branch}_*"] = {:keep => 4, :regex => /^(#{image}-#{branch})_(\d+)/}
      DEVENV_AMI_WILDCARDS["#{image}-#{branch}-base_*"] = {:keep => keep, :regex => /^(#{image}-#{branch}-base)_(\d+)/}
    end
  end
end

DEVENV_AMI_WILDCARDS["fork_ami_*"] = {:keep => 50, :keep_per_sub_group => 1, :regex => /(fork_ami_.*)_(\d+)/}

VERIFIER_REGEXS = {/^(devenv).*_(\d+)$/ => {:multiple => true},
                   /^(oso-fedora).*_(\d+)$/ => {:multiple => true},
                   /^(enterprise).*_(\d+)$/ => {:multiple => true},
                   /^((test|merge)_pull_requests).*_(\d+)$/ => {:multiple => true, :max_run_time => (60*60*2)},
                   /^(fork_ami)_.*_(\d+)$/ => {:multiple => true}}
TERMINATE_REGEX = /terminate|teminate|termiante|terminatr|terninate/
VERIFIED_TAG = "qe-ready"

# Specify the source location of the SSH key
# This will be used if the key is not found at the location specified by "RSA"
RSA = File.expand_path("~/.ssh/devenv.pem")
RSA_SOURCE = File.expand_path("../../misc/libra.pem", File.expand_path(__FILE__))
CAN_SSH_TIMEOUT=90
SLEEP_AFTER_LAUNCH=30


SIBLING_REPOS = {'enterprise-server' => ['../enterprise-server'],
                 'enterprise-rhc' => ['../enterprise-rhc'],
                 'enterprise' => ["../#{File.basename(FileUtils.pwd)}"],
                 'enterprise-dev-tools' => ['../enterprise-dev-tools'],
                 'openshift-extras' => ['../openshift-extras']}
OPENSHIFT_ARCHIVE_DIR_MAP = {'rhc' => 'rhc/'}
SIBLING_REPOS_GIT_URL = {'enterprise-server' => 'https://github.com/openshift/enterprise-server.git',
                        'enterprise-rhc' => 'https://github.com/openshift/enterprise-rhc.git',
                        'enterprise' => 'git@github.com:openshift/enterprise.git',
                        'enterprise-dev-tools' => 'git@github.com:openshift/enterprise-dev-tools.git'},
                        'openshift-extras' => 'git@github.com:openshift/openshift-extras.git'}

DEV_TOOLS_REPO = 'enterprise-dev-tools'
DEV_TOOLS_EXT_REPO = 'enterprise'
ADDTL_SIBLING_REPOS = SIBLING_REPOS_GIT_URL.keys - [DEV_TOOLS_REPO, DEV_TOOLS_EXT_REPO]

CUCUMBER_OPTIONS = '--strict -f progress -f junit --out /tmp/rhc/cucumber_results -t ~@fedora-only'
IGNORE_PACKAGES = ['rubygem-openshift-origin-auth-kerberos', 
                   'openshift-origin-cartridge-nodejs-0.6', 
                   'openshift-origin-cartridge-jbossas-7', 
                   'openshift-origin-cartridge-jbossews-2.0', 
                   'openshift-origin-cartridge-phpmyadmin-3.4',
                   'openshift-origin-cartridge-mongodb-2.2',
                   'openshift-origin-cartridge-10gen-mms-agent-0.1']

$amz_options = {:key_name => KEY_PAIR, :instance_type => TYPE}

BASE_RELEASE_BRANCH = 'devops-1-rhel-6'

JENKINS_BUILD_TOKEN = 'libra1'

#ACCEPT_DEVENV_SCRIPT = '/usr/bin/rhc-accept-devenv'
# TODO
ACCEPT_DEVENV_SCRIPT = 'true'

CHAIN_BUILD_SETS = [ ['rubygem-openshift-origin-console','rhc-site'] ]

CHAIN_BUILD_INITIATORS = ['rubygem-openshift-origin-console']

def guess_os(base_os=nil)
  "rhel"
end

def def_constants(base_os)
  nil
end
