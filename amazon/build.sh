#!/bin/bash

#wget -O openshift.ks https://raw.github.com/gist/3901379/openshift.ks
sed -e '0,/^%post/d;/^%end/,$d' ../openshift.ks > openshift-amz.sh
sed -i -e 's/2012-10-22/2012-10-23/g' openshift-amz.sh
sed -i -e 's/^configure_rhel_repo$/#&/' openshift-amz.sh
sed -i -e 's/^configure_hostname$/#&/' openshift-amz.sh
sed -i -e 's/^gpgcheck=0/gpgcheck=0\nsslverify=false/g' openshift-amz.sh

sed -i "1i CONF_NAMED_IP_ADDR=\"127.0.0.1\"" openshift-amz.sh

sed -i "1i CONF_DATASTORE_HOSTNAME=\"mongo.cloudydemo.com\"" openshift-amz.sh
sed -i "1i CONF_ACTIVEMQ_HOSTNAME=\"activemq.cloudydemo.com\"" openshift-amz.sh
sed -i "1i CONF_NODE_HOSTNAME=\"node.cloudydemo.com\"" openshift-amz.sh
sed -i "1i CONF_BROKER_HOSTNAME=\"broker.cloudydemo.com\"" openshift-amz.sh
sed -i "1i CONF_NAMED_HOSTNAME=\"ns.cloudydemo.com\"" openshift-amz.sh
sed -i "1i CONF_DOMAIN=\"apps.cloudydemo.com\"" openshift-amz.sh
