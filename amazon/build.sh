#!/bin/bash

wget https://raw.github.com/gist/3901379/45782dc6b168282823a87bb15f9bb81c0d0773bc/openshift.ks openshift.ks
sed -e '0,/^%post/d;/^%end/,$d' openshift.ks > openshift-amz.sh
rm openshift.ks
sed -i -e 's/2012-10-22/2012-10-23/g' openshift-amz.sh
sed -i -e 's/^configure_rhel_repo$/#&/' openshift-amz.sh
sed -i -e 's/^gpgcheck=0/gpgcheck=0\nsslverify=false/g' openshift-amz.sh
sed -i "1i CONF_INSTALL_COMPONENTS=broker,node,activemq,datastore" openshift-amz.sh
