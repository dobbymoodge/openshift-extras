# Global definitions
require 'fileutils'

AMI = {"us-east-1" => "ami-938c5dfa"}
TYPE = "m1.large"  # default size of instance to use with the AMI

DEVENV_NAME = 'enterprise'

# where to find the key to ssh to the instance
RSA = File.expand_path("~/.ssh/libra.pem")
KEY_PAIR = "libra"
CAN_SSH_TIMEOUT=90

# need these due to hardwired inherited code
ZONE = 'us-east-1'
IGNORE_PACKAGES = ['rubygem-openshift-origin-auth-kerberos', 
                   'openshift-origin-cartridge-nodejs-0.6', 
                   'openshift-origin-cartridge-jbossas-7', 
                   'openshift-origin-cartridge-jbossews-2.0', 
                   'openshift-origin-cartridge-phpmyadmin-3.4',
                   'openshift-origin-cartridge-mongodb-2.2',
                   'openshift-origin-cartridge-10gen-mms-agent-0.1']
$amz_options = {:key_name => KEY_PAIR, :instance_type => TYPE}
# not sure what we'll do with this yet
VERIFIED_TAG = "qe-ready"

SIBLING_REPOS = {'enterprise-server' => ['../enterprise-server'],
                 'enterprise-rhc' => ['../enterprise-rhc'],
                 'enterprise' => ["../#{File.basename(FileUtils.pwd)}"],
                 'enterprise-dev-tools' => ['../enterprise-dev-tools'],
                 'openshift-extras' => ['../openshift-extras']}
SIBLING_REPOS_GIT_URL = {'enterprise-server' => 'git@github.com:openshift/enterprise-server.git',
                        'enterprise-rhc' => 'git@github.com:openshift/enterprise-rhc.git',
                        'enterprise' => 'git@github.com:openshift/enterprise.git',
                        'enterprise-dev-tools' => 'git@github.com:openshift/enterprise-dev-tools.git',
                        'openshift-extras' => 'git@github.com:openshift/openshift-extras.git'}

DEV_TOOLS_REPO = 'enterprise-dev-tools'
DEV_TOOLS_EXT_REPO = 'enterprise'
ADDTL_SIBLING_REPOS = SIBLING_REPOS_GIT_URL.keys - [DEV_TOOLS_REPO, DEV_TOOLS_EXT_REPO]

BASE_RELEASE_BRANCH = '???'

JENKINS_BUILD_TOKEN = 'libra1'

CUCUMBER_OPTIONS = '--strict -f progress -f junit --out /tmp/rhc/cucumber_results -t ~@not-origin ~@not-enterprise'

ACCEPT_DEVENV_SCRIPT = 'true'
