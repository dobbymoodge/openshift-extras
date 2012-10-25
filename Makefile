all: internal/openshift-internal.ks amazon/openshift-amz.sh

clean:
	rm -f internal/openshift-internal.ks amazon/openshift-amz.sh

internal/openshift-internal.ks: openshift.ks
	cp -f openshift.ks $@
	sed -i -e 's/^gpgcheck=0/gpgcheck=0\nsslverify=false/g' $@
	ruby -p -i -e 'if $$_ =~ /yum-config-manager --enable rhel-6-server-optional-rpms/; $$_ = "  #" + $$_[2..-1] + "  cat <<EOF > /etc/yum.repos.d/rhel.repo\n" + File.open("internal/rhel.repo").read + "\nEOF\n" end' $@

amazon/openshift-amz.sh: openshift.ks
	sed -e '0,/^%post/d;/^%end/,$$d' openshift.ks > $@
	sed -i -e 's/2012-10-22/2012-10-23/g' $@
	sed -i -e 's/^configure_rhel_repo$$/#&/' $@
	sed -i -e 's/^configure_hostname$$/#&/' $@
	sed -i -e 's/^gpgcheck=0/gpgcheck=0\nsslverify=false/g' $@
	
	sed -i "1i CONF_NAMED_IP_ADDR=\"127.0.0.1\"" $@
	
	sed -i "1i CONF_DATASTORE_HOSTNAME=\"mongo.cloudydemo.com\"" $@
	sed -i "1i CONF_ACTIVEMQ_HOSTNAME=\"activemq.cloudydemo.com\"" $@
	sed -i "1i CONF_NODE_HOSTNAME=\"node.cloudydemo.com\"" $@
	sed -i "1i CONF_BROKER_HOSTNAME=\"broker.cloudydemo.com\"" $@
	sed -i "1i CONF_NAMED_HOSTNAME=\"ns.cloudydemo.com\"" $@
	sed -i "1i CONF_DOMAIN=\"apps.cloudydemo.com\"" $@
