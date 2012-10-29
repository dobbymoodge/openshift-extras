# Global definitions
require 'fileutils'

AMI = {"us-east-1" => "ami-938c5dfa"}
TYPE = "m1.large"  # default size of instance to use with the AMI

DEVENV_NAME = 'devops'

# where to find the key to ssh to the instance
RSA = File.expand_path("~/.ssh/libra.pem")
KEY_PAIR = "libra"
CAN_SSH_TIMEOUT=90

# need these due to hardwired inherited code
SAUCE_USER = ""
SAUCE_SECRET = ""
ZONE = 'us-east-1'
$amz_options = {:key_name => KEY_PAIR, :instance_type => TYPE}
# not sure what we'll do with this yet
VERIFIED_TAG = "qe-ready"


SIBLING_REPOS = {'origin-server' => ['../origin-server'],
                 'rhc' => ['../rhc'],
                 'enterprise-install' => ["../#{File.basename(FileUtils.pwd)}"],
                 'origin-dev-tools' => ['../origin-dev-tools']}
SIBLING_REPOS_GIT_URL = {'origin-server' => 'https://github.com/openshift/origin-server.git',
                        'rhc' => 'https://github.com/openshift/rhc.git',
                        'enterprise-install' => 'git@github.com:openshift/enterprise-install.git',
                        'origin-dev-tools' => 'git@github.com:openshift/origin-dev-tools.git'}
                        
DEV_TOOLS_REPO = 'origin-dev-tools'
DEV_TOOLS_EXT_REPO = 'enterprise-install'
ADDTL_SIBLING_REPOS = SIBLING_REPOS_GIT_URL.keys - [DEV_TOOLS_REPO, DEV_TOOLS_EXT_REPO]