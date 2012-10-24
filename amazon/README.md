Amazon Installation
==================

Running
-------
*Important:* These AMI's won't have charlie so make sure to turn it off when you are done.

1. Create an AMI instance from ami-ee0eaf87 (RHEL-6.3-Starter-x86_64-1-Access2).
2. Upload the openshift-amz.sh script to them
3. Run it


Updating from the source kickstart
----------------------------------

The general updating process for refreshing the openshift-amz.sh script
is as follows.

1. Convert the internal kickstart to a script

    sed -e '0,/^%post/d;/^%end/,$d' ../internal/openshift-internal.ks > openshift-amz.sh

2. Replace all the internal repository links with the public mirror
   locations

    sed -i -e 's%buildvm-devops.usersys.redhat.com/puddle/build/OpenShiftEnterprise/Beta%mirror.openshift.com/pub/origin-server/nightly/enterprise%g' openshift-amz.sh

3. Note: You might need to replace the dates when mapping the internal
   repositories to the external ones.

    sed -i -e 's/2012-10-22.2/2012-10-23/g' openshift-amz.sh

4. Comment out the internal RHEL repository

    sed -i -e 's/^configure_rhel_repo$/#&/' openshift-amz.sh

5. Setup script to configure the node and broker

    sed -i "1i CONF_INSTALL_BROKER=true\nCONF_INSTALL_NODE=true" openshift-amz.sh
