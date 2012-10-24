Amazon Installation
==================

Running
-------
*Important:* These AMI's won't have charlie so make sure to turn it off when you are done.

1. Create an AMI instance from ami-ee0eaf87 (RHEL-6.3-Starter-x86_64-1-Access2).
2. Upload the openshift-amz.sh script to your instance
3. Run it
    sh openshift-amz.sh


Updating from the source kickstart
----------------------------------

The general updating process for refreshing the openshift-amz.sh script
is as follows.

*Note:* This is automated in the build.sh file

1. Download the public gist kickstart

    wget https://raw.github.com/gist/3901379/openshift.ks

1. Convert the kickstart to a script and delete the download

    sed -e '0,/^%post/d;/^%end/,$d' openshift.ks > openshift-amz.sh
    rm openshift.ks

2. Note: You might need to replace the dates to the latest

    sed -i -e 's/2012-10-22/2012-10-23/g' openshift-amz.sh

3. Comment out the internal RHEL repository

    sed -i -e 's/^configure_rhel_repo$/#&/' openshift-amz.sh

4. Disable SSL verification for all OpenShift repos

    sed -i -e 's/^gpgcheck=0/gpgcheck=0\nsslverify=false/g' openshift-amz.sh

5. Setup script to configure the node and broker

    sed -i "1i CONF_INSTALL_COMPONENTS=\"broker node activemq datastore\"" openshift-amz.sh
