Amazon Installation
==================

Running
-------
*Important:* These AMI's won't have charlie so make sure to turn it off when you are done.

1. Create an AMI instance from ami-ee0eaf87 (RHEL-6.3-Starter-x86_64-1-Access2).
2. Upload the openshift-amz.sh script to your instance
3. Run it
    CONF_PREFIX="myprefix" && sh openshift-amz.sh


Updating from the source kickstart
----------------------------------

The general updating process for refreshing the openshift-amz.sh script
is as follows.

*Note:* This is automated in the build.sh file

1. Download the latest kickstart into the root directory as
   'openshift.ks'

    wget https://raw.github.com/gist/3901379/openshift.ks

2. Run the build script

    cd amazon
    ./build.sh
