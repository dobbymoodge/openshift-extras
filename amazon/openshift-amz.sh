CONF_INSTALL_BROKER=true
CONF_INSTALL_NODE=true


# You can tail the log file showing the execution of the commands below
# by using the following command:
#    tailf /mnt/sysimage/root/anaconda-post.log

# You can use sed to extract just the %post section:
#    sed -e '0,/^%post/d;/^%end/,$d'

# Log the command invocations (and not merely output) in order to make
# the log more useful.
set -x


########################################################################

# Synchronize the system clock to the NTP servers and then synchronize
# hardware clock with that.
synchronize_clock()
{
  # Synchronize the system clock using NTP.
  ntpdate clock.redhat.com

  # Synchronize the hardware clock to the system clock.
  hwclock --systohc
}


# Install SSH keys.  We hardcode a key used for internal OpenShift
# development, but the hardcoded key can be replaced with another or
# with a wget command to download a key from elsewhere.
install_ssh_keys()
{
  mkdir /root/.ssh
  chmod 700 /root/.ssh
  cat >> /root/.ssh/authorized_keys << KEYS
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkMc2jArUbWICi0071HXrt5uofQam11duqo5KEDWUZGtHuMTzuoZ0XEtzpqoRSidya9HjbJ5A4qUJBrvLZ07l0OIjENQ0Kvz83alVGFrEzVVUSZyiy6+yM9Ksaa/XAYUwCibfaFFqS9aVpVdY0qwaKrxX1ycTuYgNAw3WUvkHagdG54/79M8BUkat4uNiot0bKg6VLSI1QzNYV6cMJeOzz7WzHrJhbPrgXNKmgnAwIKQOkbATYB+YmDyHpA4m/O020dWDk9vWFmlxHLZqddCVGAXFyQnXoFTszFP4wTVOu1q2MSjtPexujYjTbBBxraKw9vrkE25YZJHvbZKMsNm2b libra_onprem
KEYS
}


configure_rhel_repo()
{
  # Enable the optional channel.
  #yum-config-manager --enable rhel-6-server-optional-rpms

  # Enable internal RHEL repos (main + extras).
  cat >> /etc/yum.repos.d/rhel.repo << RHEL
[rhel63]
name=rhel63
baseurl=http://cdn-internal.rcm-test.redhat.com/content/dist/rhel/server/6/6Server/x86_64/os/
enabled=1
gpgcheck=0

RHEL
}

configure_client_tools_repo()
{
  # Enable repo with the puddle for broker packages.
  cat >> /etc/yum.repos.d/openshift-client.repo << YUM
[openshift_client]
name=OpenShift Client
baseurl=http://mirror.openshift.com/pub/origin-server/nightly/enterprise/2012-10-23/Client/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false

YUM
}

configure_broker_repo()
{
  # Enable repo with the puddle for broker packages.
  cat >> /etc/yum.repos.d/openshift-infrastructure.repo << YUM
[openshift_infrastructure]
name=OpenShift Infrastructure
baseurl=http://mirror.openshift.com/pub/origin-server/nightly/enterprise/2012-10-23/Infrastructure/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false

YUM
}

configure_node_repo()
{
  # Enable repo with the puddle for node packages.
  cat >> /etc/yum.repos.d/openshift-node.repo << YUM
[openshift_node]
name=OpenShift Node
baseurl=http://mirror.openshift.com/pub/origin-server/nightly/enterprise/2012-10-23/Node/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false

YUM
}

configure_jboss_cartridge_repo()
{
  # Enable repo with the puddle for the JBossEAP cartridge package.
  cat >> /etc/yum.repos.d/openshift-jboss.repo << YUM
[openshift_jbosseap]
name=OpenShift JBossEAP
baseurl=http://mirror.openshift.com/pub/origin-server/nightly/enterprise/2012-10-23/JBoss_EAP6_Cartridge/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false

YUM
}

# Install the client tools.
install_rhc_pkg()
{
  yum install -y rhc
}

# Install broker-specific packages.
install_broker_pkgs()
{
  # Kickstart doesn't handle line continuations.
  pkgs="openshift-origin-broker"
  pkgs="$pkgs openshift-origin-broker-util"
  pkgs="$pkgs rubygem-openshift-origin-msg-broker-mcollective"
  pkgs="$pkgs rubygem-openshift-origin-auth-remote-user"
  pkgs="$pkgs rubygem-openshift-origin-dns-bind"

  yum install -y $pkgs
}

# Install node-specific packages.
install_node_pkgs()
{
  # Kickstart doesn't handle line continuations.
  pkgs="rubygem-openshift-origin-node rubygem-passenger-native"
  pkgs="$pkgs openshift-origin-port-proxy"
  pkgs="$pkgs openshift-origin-node-util"

  yum install -y $pkgs
}

# Install any cartridges developers may want.
install_cartridges()
{
  :
  # Following are cartridge rpms that one may want to install here:

  # Embedded cron support.
  yum install openshift-origin-cartridge-cron-1.4 -y

  # diy app.
  yum install openshift-origin-cartridge-diy-0.1 -y

  # haproxy-1.4 support.
  #yum install openshift-origin-cartridge-haproxy-1.4 -y

  # JBossEWS1.0 support.
  #yum install openshift-origin-cartridge-jbossews-1.0 -y

  # JBossEAP6.0 support.
  #yum install openshift-origin-cartridge-jbosseap-6.0 -y

  # Jenkins server for continuous integration.
  #yum install openshift-origin-cartridge-jenkins-1.4 -y

  # Embedded jenkins client.
  #yum install openshift-origin-cartridge-jenkins-client-1.4 -y

  # Embedded MySQL.
  #yum install openshift-origin-cartridge-mysql-5.1 -y

  # mod_perl support.
  #yum install openshift-origin-cartridge-perl-5.10 -y

  # PHP 5.3 support.
  yum install openshift-origin-cartridge-php-5.3 -y

  # Embedded PostgreSQL.
  #yum install openshift-origin-cartridge-postgresql-8.4 -y

  # Python 2.6 support.
  #yum install openshift-origin-cartridge-python-2.6 -y

  # Ruby Rack support running on Phusion Passenger (Ruby 1.8).
  #yum install openshift-origin-cartridge-ruby-1.8 -y

  # Ruby Rack support running on Phusion Passenger (Ruby 1.9).
  #yum install openshift-origin-cartridge-ruby-1.9 -y
}

# Fix up SELinux policy on the broker.
configure_selinux_policy_on_broker()
{
  # We combine these setsebool commands into a single semanage command
  # because separate commands take a long time to run.
  (
    # Allow the broker to write files in the http file context.
    echo boolean -m --on httpd_unified

    # Allow the broker to access the network.
    echo boolean -m --on httpd_can_network_connect
    echo boolean -m --on httpd_can_network_relay

    # Enable some passenger-related permissions.
    #
    # The name may change at some future point, at which point we will
    # need to delete the httpd_run_stickshift line below and enable the
    # httpd_run_openshift line.
    echo boolean -m --on httpd_run_stickshift
    #echo boolean -m --on httpd_run_openshift

    # Allow the broker to configure DNS.
    echo boolean -m --on named_write_master_zones

    # Allow ypbind so that the broker can communicate directly with the name
    # server.
    echo boolean -m --on allow_ypbind
  ) | semanage -i -

  fixfiles -R rubygem-passenger restore
  fixfiles -R mod_passenger restore

  restorecon -R -v /var/run
  restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-*
}

# Fix up SELinux policy on the node.
configure_selinux_policy_on_node()
{
  # This is a temporary measure until selinux-policy is updated.
  pushd /usr/share/selinux/targeted
  wget https://gist.github.com/raw/3901379/ce907e7a4bd6f586f8e313c2b95d6cdaa7bcb830/pam_openshift.pp
  semodule -i pam_openshift.pp
  popd

  # We combine these setsebool commands into a single semanage command
  # because separate commands take a long time to run.
  (
    # Allow the node to write files in the http file context.
    echo boolean -m --on httpd_unified

    # Allow the node to access the network.
    echo boolean -m --on httpd_can_network_connect
    echo boolean -m --on httpd_can_network_relay

    # Allow httpd on the node to read gear data.
    #
    # The name may change at some future point, at which point we will
    # need to delete the httpd_run_stickshift line below and enable the
    # httpd_run_openshift line.
    echo boolean -m --on httpd_run_stickshift
    #echo boolean -m --on httpd_run_openshift
    echo boolean -m --on httpd_read_user_content
    echo boolean -m --on httpd_enable_homedirs

    # Enable polyinstantiation for gear data.
    echo boolean -m --on allow_polyinstantiation
  ) | semanage -i -

  fixfiles -R rubygem-passenger restore
  fixfiles -R mod_passenger restore

  restorecon -rv /var/run
  restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-*
  restorecon -rv /usr/sbin/mcollectived /var/log/mcollective.log /var/run/mcollectived.pid
  restorecon -rv /var/lib/openshift /etc/openshift/node.conf /etc/httpd/conf.d/openshift
}

configure_pam_on_node()
{
  sed -i -e 's|pam_selinux|pam_openshift|g' /etc/pam.d/sshd

  # The pam_namespace work is not ready to be enabled yet.
  #for f in "runuser" "runuser-l" "sshd" "su" "system-auth-ac"
  #do
  #  t="/etc/pam.d/$f"
  #  if ! grep -q "pam_namespace.so" "$t"
  #  then
  #    echo -e "session\t\trequired\tpam_namespace.so no_unmount_on_close" >> "$t"
  #  fi
  #done
}

configure_cgroups_on_node()
{
  cp /usr/share/doc/*/cgconfig.conf /etc/cgconfig.conf
  restorecon -v /etc/cgconfig.conf
  mkdir /cgroup
  restorecon -v /cgroup
  chkconfig cgconfig on
  chkconfig cgred on
  chkconfig openshift-cgroups on
}

# Turn some sysctl knobs.
configure_sysctl_on_node()
{
  # Increase kernel semaphores to accomodate many httpds.
  echo "kernel.sem = 250  32000 32  4096" >> /etc/sysctl.conf

  # Move ephemeral port range to accommodate app proxies.
  echo "net.ipv4.ip_local_port_range = 15000 35530" >> /etc/sysctl.conf

  # Increase the connection tracking table size.
  echo "net.netfilter.nf_conntrack_max = 1048576" >> /etc/sysctl.conf

  # Reload sysctl.conf to get the new settings.
  #
  # Note: We could add -e here to ignore errors that are caused by
  # options appearing in sysctl.conf that correspond to kernel modules
  # that are not yet loaded.  On the other hand, adding -e might cause
  # us to miss some important error messages.
  sysctl -p /etc/sysctl.conf
}


configure_sshd_on_node()
{
  # Configure sshd to pass the GIT_SSH environment variable through.
  echo 'AcceptEnv GIT_SSH' >> /etc/ssh/sshd_config

  # Up the limits on the number of connections to a given node.
  perl -p -i -e "s/^#MaxSessions .*$/MaxSessions 40/" /etc/ssh/sshd_config
  perl -p -i -e "s/^#MaxStartups .*$/MaxStartups 40/" /etc/ssh/sshd_config
}

# Configure MongoDB datastore.
configure_datastore()
{
  # Install MongoDB.
  yum install -y mongodb-server

  # Require authentication.
  perl -p -i -e "s/^#auth = .*$/auth = true/" /etc/mongodb.conf

  # Use a smaller default size for databases.
  if [ "x`fgrep smallfiles=true /etc/mongodb.conf`x" != "xsmallfiles=truex" ]
  then
    echo 'smallfiles=true' >> /etc/mongodb.conf
  fi

  # Configure mongod to start on boot.
  chkconfig mongod on

  # Start mongod so we can perform some administration now.
  service mongod start
}


# Open up services required on the node for apps and developers.
configure_port_proxy()
{
  lokkit --nostart --port=35531-65535:tcp

  chkconfig openshift-port-proxy on
}


# Enable services to start on boot for the node.
enable_services_on_node()
{
  # We use --nostart below because activating the configuration here will
  # produce errors.  Anyway, we only need the configuration activated
  # after Anaconda reboots, so --nostart makes sense in any case.

  lokkit --nostart --service=ssh
  lokkit --nostart --service=https
  lokkit --nostart --service=http

  chkconfig httpd on
  chkconfig network on
  chkconfig sshd on
}


# Enable services to start on boot for the broker.
enable_services_on_broker()
{
  # We use --nostart below because activating the configuration here will
  # produce errors.  Anyway, we only need the configuration activated
  # after Anaconda reboots, so --nostart makes sense in any case.

  lokkit --nostart --service=ssh
  lokkit --nostart --service=https
  lokkit --nostart --service=http

  chkconfig httpd on
  chkconfig network on
  chkconfig ntpd on
  chkconfig sshd on
}


# Configure mcollective on the broker to use qpid.
configure_mcollective_for_qpid_on_broker()
{
  yum install -y mcollective-client

  cat <<EOF > /etc/mcollective/client.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
loglevel = debug
logfile = /var/log/mcollective-client.log

# Plugins
securityprovider = psk
plugin.psk = unset
connector = qpid
plugin.qpid.host = ${broker_hostname}.${domain}
plugin.qpid.secure = false
plugin.qpid.timeout = 5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF
}


# Configure mcollective on the broker to use qpid.
configure_mcollective_for_qpid_on_node()
{
  yum install -y mcollective openshift-origin-msg-node-mcollective

  cat <<EOF > /etc/mcollective/server.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /var/log/mcollective.log
loglevel = debug
daemonize = 1
direct_addressing = n

# Plugins
securityprovider = psk
plugin.psk = unset
connector = qpid
plugin.qpid.host = ${broker_hostname}.${domain}
plugin.qpid.secure = false
plugin.qpid.timeout = 5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF

  chkconfig mcollective on
}


# Configure mcollective on the broker to use ActiveMQ.
configure_mcollective_for_activemq_on_broker()
{
  yum install -y mcollective-client

  cat <<EOF > /etc/mcollective/client.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /var/log/mcollective-client.log
loglevel = debug

# Plugins
securityprovider=psk
plugin.psk=unset

connector = stomp
plugin.stomp.host = localhost
plugin.stomp.port = 61613
plugin.stomp.user = mcollective
plugin.stomp.password = marionette
EOF
}


# Configure mcollective on the broker to use qpid.
configure_mcollective_for_activemq_on_node()
{
  yum install -y mcollective openshift-origin-msg-node-mcollective

  cat <<EOF > /etc/mcollective/server.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /var/log/mcollective.log
loglevel = debug
daemonize = 1
direct_addressing = n

# Plugins
securityprovider = psk
plugin.psk = unset

connector = stomp
plugin.stomp.host = ${broker_hostname}.${domain}
plugin.stomp.port = 61613
plugin.stomp.user = mcollective
plugin.stomp.password = marionette

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF

  chkconfig mcollective on
}


# Configure ActiveMQ.
configure_activemq()
{
  # Install the service.
  yum install -y activemq activemq-client

  cat <<EOF > /etc/activemq/activemq.xml
<!--
    Licensed to the Apache Software Foundation (ASF) under one or more
    contributor license agreements.  See the NOTICE file distributed with
    this work for additional information regarding copyright ownership.
    The ASF licenses this file to You under the Apache License, Version 2.0
    (the "License"); you may not use this file except in compliance with
    the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
-->
<beans
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:amq="http://activemq.apache.org/schema/core"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
  http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd">

    <!-- Allows us to use system properties as variables in this configuration file -->
    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <value>file:\${activemq.conf}/credentials.properties</value>
        </property>
    </bean>

    <!--
        The <broker> element is used to configure the ActiveMQ broker.
    -->
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="${broker_hostname}.${domain}" dataDirectory="\${activemq.data}">

        <!--
            For better performances use VM cursor and small memory limit.
            For more information, see:

            http://activemq.apache.org/message-cursors.html

            Also, if your producer is "hanging", it's probably due to producer flow control.
            For more information, see:
            http://activemq.apache.org/producer-flow-control.html
        -->

        <destinationPolicy>
            <policyMap>
              <policyEntries>
                <policyEntry topic=">" producerFlowControl="true" memoryLimit="1mb">
                  <pendingSubscriberPolicy>
                    <vmCursor />
                  </pendingSubscriberPolicy>
                </policyEntry>
                <policyEntry queue=">" producerFlowControl="true" memoryLimit="1mb">
                  <!-- Use VM cursor for better latency
                       For more information, see:

                       http://activemq.apache.org/message-cursors.html

                  <pendingQueuePolicy>
                    <vmQueueCursor/>
                  </pendingQueuePolicy>
                  -->
                </policyEntry>
              </policyEntries>
            </policyMap>
        </destinationPolicy>


        <!--
            The managementContext is used to configure how ActiveMQ is exposed in
            JMX. By default, ActiveMQ uses the MBean server that is started by
            the JVM. For more information, see:

            http://activemq.apache.org/jmx.html
        -->
        <managementContext>
            <managementContext createConnector="false"/>
        </managementContext>

        <!--
            Configure message persistence for the broker. The default persistence
            mechanism is the KahaDB store (identified by the kahaDB tag).
            For more information, see:

            http://activemq.apache.org/persistence.html
        -->
        <persistenceAdapter>
            <kahaDB directory="\${activemq.data}/kahadb"/>
        </persistenceAdapter>

        <!-- add users for mcollective -->

        <plugins>
          <statisticsBrokerPlugin/>
          <simpleAuthenticationPlugin>
             <users>
               <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
               <authenticationUser username="admin" password="secret" groups="mcollective,admin,everyone"/>
             </users>
          </simpleAuthenticationPlugin>
          <authorizationPlugin>
            <map>
              <authorizationMap>
                <authorizationEntries>
                  <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <authorizationEntry queue="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
                </authorizationEntries>
              </authorizationMap>
            </map>
          </authorizationPlugin>
        </plugins>

          <!--
            The systemUsage controls the maximum amount of space the broker will
            use before slowing down producers. For more information, see:
            http://activemq.apache.org/producer-flow-control.html
            If using ActiveMQ embedded - the following limits could safely be used:

        <systemUsage>
            <systemUsage>
                <memoryUsage>
                    <memoryUsage limit="20 mb"/>
                </memoryUsage>
                <storeUsage>
                    <storeUsage limit="1 gb"/>
                </storeUsage>
                <tempUsage>
                    <tempUsage limit="100 mb"/>
                </tempUsage>
            </systemUsage>
        </systemUsage>
        -->
          <systemUsage>
            <systemUsage>
                <memoryUsage>
                    <memoryUsage limit="64 mb"/>
                </memoryUsage>
                <storeUsage>
                    <storeUsage limit="100 gb"/>
                </storeUsage>
                <tempUsage>
                    <tempUsage limit="50 gb"/>
                </tempUsage>
            </systemUsage>
        </systemUsage>

        <!--
            The transport connectors expose ActiveMQ over a given protocol to
            clients and other brokers. For more information, see:

            http://activemq.apache.org/configuring-transports.html
        -->
        <transportConnectors>
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
            <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>
        </transportConnectors>

    </broker>

    <!--
        Enable web consoles, REST and Ajax APIs and demos

        Take a look at \${ACTIVEMQ_HOME}/conf/jetty.xml for more details
    -->
    <import resource="jetty.xml"/>

</beans>
<!-- END SNIPPET: example -->
EOF

  # Allow connections to ActiveMQ.
  lokkit --nostart --port=61613:tcp

  # Configure ActiveMQ to start on boot.
  chkconfig activemq on
}


# Configure qpid.
configure_qpid()
{
  if [[ "x`fgrep auth= /etc/qpidd.conf`" == xauth* ]]
  then
    sed -i -e 's/auth=yes/auth=no/' /etc/qpidd.conf
  else
    echo "auth=no" >> /etc/qpidd.conf
  fi

  # Allow connections to qpidd.
  lokkit --nostart --port=5672:tcp

  # Configure qpidd to start on boot.
  chkconfig qpidd on
}


# Configure BIND.
configure_named()
{
  yum install -y bind bind-utils

  # $keyfile will contain a new DNSSEC key for our domain.
  keyfile=/var/named/${domain}.key

  # Generate the new key for the domain.
  rm -f /var/named/K${domain}*
  pushd /var/named
  dnssec-keygen -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${domain}
  KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"
  popd

  # Ensure we have a key for the broker to communicate with BIND.
  rndc-confgen -a -r /dev/urandom
  restorecon /etc/rndc.* /etc/named.*
  chown root:named /etc/rndc.key
  chmod 640 /etc/rndc.key

  # Set up DNS forwarding.
  cat <<EOF > /var/named/forwarders.conf
forwarders { ${nameservers} } ;
EOF
  restorecon /var/named/forwarders.conf
  chmod 755 /var/named/forwarders.conf

  # Install the configuration file for the OpenShift Enterprise domain
  # name.
  rm -rf /var/named/dynamic
  mkdir -p /var/named/dynamic

  cat <<EOF > /var/named/dynamic/${domain}.db
\$ORIGIN .
\$TTL 1	; 1 seconds (for testing only)
${domain}		IN SOA	ns1.${domain}. hostmaster.${domain}. (
				2011112904 ; serial
				60         ; refresh (1 minute)
				15         ; retry (15 seconds)
				1800       ; expire (30 minutes)
				10         ; minimum (10 seconds)
				)
			NS	ns1.${domain}.
			MX	10 mail.${domain}.
\$ORIGIN ${domain}.
ns1			A	127.0.0.1

EOF

  # Install the key for the OpenShift Enterprise domain.
  cat <<EOF > /var/named/${domain}.key
key ${domain} {
  algorithm HMAC-MD5;
  secret "${KEY}";
};
EOF

  chown named:named -R /var/named
  restorecon -R /var/named

  # Replace named.conf.
  cat <<EOF > /etc/named.conf
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
	listen-on port 53 { any; };
	listen-on port 953 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; };
	recursion yes;

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.iscdlv.key";

	// set forwarding to the next nearest server (from DHCP response
	forward only;
        include "forwarders.conf";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// use the default rndc key
include "/etc/rndc.key";
 
controls {
	inet 127.0.0.1 port 953
	allow { 127.0.0.1; } keys { "rndc-key"; };
};

include "/etc/named.rfc1912.zones";

include "${domain}.key";

zone "${domain}" IN {
	type master;
	file "dynamic/${domain}.db";
	allow-update { key ${domain} ; } ;
};
EOF
  chown root:named /etc/named.conf
  chcon system_u:object_r:named_conf_t:s0 -v /etc/named.conf

  # Configure named to start on boot.
  lokkit --nostart --service=dns
  chkconfig named on

  # Start named so we can perform some updates immediately.
  service named start

  # Tell BIND about the broker.
  nsupdate -k ${keyfile} <<EOF
server 127.0.0.1
update delete ${broker_hostname}.${domain} A
update add ${broker_hostname}.${domain} 180 A ${broker_ip_addr}
send
EOF
}


# Make resolv.conf point to localhost to use the newly configured named
# on the broker.
update_resolv_conf_on_broker()
{
  # Update resolv.conf to use the local BIND instance.
  cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF
}


# Make resolv.conf point to the broker, which will resolve the host
# names used in this installation of OpenShift.  The broker will forward
# other requests to some other DNS servers.
# on the broker.
update_resolv_conf_on_node()
{
  # Update resolv.conf to use the broker.
  cat <<EOF > /etc/resolv.conf
nameserver ${broker_ip_addr}
EOF
}


# Update the controller configuration.
configure_controller()
{
  perl -p -i -e "s/.*:domain_suffix.*/    :domain_suffix => \"${domain}\",/" /var/www/openshift/broker/config/environments/*.rb
  # */ # What the heck, VIM syntax highlighting? Kickstart scripts do not use
  #  C-style comments.

  # Configure the broker service to start on boot.
  chkconfig openshift-broker on
}

# Set the administrative password for the database.
configure_mongo_password()
{
  # The init script lies to us as of version 2.0.2-1.el6_3: The start and
  # restart actions return before the daemon is ready to accept
  # connections (it appears to take time to initialize the journal).  Thus
  # we need the following to wait until the daemon is really ready.
  echo "Waiting for MongoDB to start ($(date +%H:%M:%S))..."
  while :
  do
    echo exit | mongo && break
    sleep 5
  done
  echo "MongoDB is ready! ($(date +%H:%M:%S))"

  mongo openshift_broker_dev --eval 'db.addUser("openshift", "mooo")'

  # If you change the above password of "mooo" to something else, be
  # sure to edit and enable the following line:
  #sed -i -e '/:password => "mooo"/s/mooo/<password>/' /var/www/openshift/broker/config/environments/development.rb
}

# Configure the broker to use the remote-user authentication plugin.
configure_auth_plugin()
{
  cp /etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf{.example,}
}

configure_messaging_plugin()
{
  cp /etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf{.example,}
}

# Configure the broker to use the BIND DNS plug-in.
configure_dns_plugin()
{
  mkdir -p /etc/openshift/plugins.d
  cat <<EOF > /etc/openshift/plugins.d/openshift-origin-dns-bind.conf
BIND_SERVER="127.0.0.1"
BIND_PORT=53
BIND_KEYNAME="${domain}"
BIND_KEYVALUE="${KEY}"
BIND_ZONE="${domain}"
EOF

  pushd /usr/share/selinux/packages/openshift-origin-dns-bind/ && make -f /usr/share/selinux/devel/Makefile ; popd
  semodule -i /usr/share/selinux/packages/openshift-origin-dns-bind/dhcpnamedforward.pp
}

# Configure httpd for authentication.
configure_httpd_auth()
{
  # Install the Apache configuration file.
  cp /var/www/openshift/broker/httpd/conf.d/openshift-origin-auth-remote-user.conf{.sample,}

  # The above configuration file configures Apache to use
  # /etc/openshift/htpasswd for its password file.  Use the following
  # command to add users:
  #
  #  htpasswd -c /etc/openshift/htpasswd username

  # Generate the broker key.
  openssl genrsa -out /etc/openshift/server_priv.pem 2048
  openssl rsa -in /etc/openshift/server_priv.pem -pubout > /etc/openshift/server_pub.pem

  # TODO: In the future, we will want to edit
  # /etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf to
  # put in a random salt.
}

# Configure IP address and hostname.
configure_network()
{
  # Append some stuff to the DHCP configuration.
  cat <<EOF >> /etc/dhcp/dhclient-eth0.conf

prepend domain-name-servers ${broker_ip_addr};
supersede host-name "${hostname}";
supersede domain-name "${domain}";
EOF

  # Set the hostname.
  sed -i -e "s/HOSTNAME=.*/HOSTNAME=${hostname}.${domain}/" /etc/sysconfig/network
  hostname "${hostname}"
}


# Set some parameters in the OpenShift node configuration file.
configure_node()
{
  sed -i -e "s/^PUBLIC_IP=.*$/PUBLIC_IP=${node_ip_addr}/;
             s/^CLOUD_DOMAIN=.*$/CLOUD_DOMAIN=${domain}/;
             s/^PUBLIC_HOSTNAME=.*$/PUBLIC_HOSTNAME=${hostname}.${domain}/;
             s/^BROKER_HOST=.*$/BROKER_HOST=${broker_ip_addr}/" \
      /etc/openshift/node.conf
}

# Run the cronjob installed by openshift-origin-msg-node-mcollective immediately
# to regenerate facts.yaml.
update_openshift_facts_on_node()
{
  /etc/cron.minutely/openshift-facts
}


########################################################################

#
# Parse the kernel command-line, define variables with the parameters
# specified on it, and define functions broker() and node(), which
# return true or false as appropriate based on whether we are
# configuring the host as a broker or as a node.
#

for word in $(cat /proc/cmdline)
do
  key="${word%%\=*}"
  case "$word" in
    (*=*) val="${word#*\=}" ;;
    (*) val=true ;;
  esac
  export CONF_${key^^}="$val"
done

# Define broker and node functions which return true or false as
# appropriate based on whether we are configuring the host as a broker
# or as a node.
[[ $CONF_INSTALL_BROKER =~ (1|true) ]] && broker() { :; } || broker() { false; }

[[ $CONF_INSTALL_NODE =~ (1|true) ]] && node() { :; } || node() { false; }

# If neither node nor broker is specified, define both broker and node
# to true so we install everything.
node || broker || { broker() { :; }; node() { :; }; }

node && echo Installing node components.
broker && echo Installing broker components.

#
# Following are some settings used in subsequent steps.
#

# The domain name for this OpenShift Enterprise installation.
domain="${CONF_DOMAIN:-example.com}"

# The hostname of the broker.
broker_hostname="${CONF_BROKER_HOSTNAME:-broker}"

# The hostname of the node.
node_hostname="${CONF_NODE_HOSTNAME:-node}"

# The hostname name for this host.
node && hostname="$node_hostname"
broker && hostname="$broker_hostname"

# The IP address of the broker.  If no IP address is given on the kernel
# command-line, the IP address of the current host is used.
broker_ip_addr="${CONF_BROKER_IP_ADDR:-$(/sbin/ip addr show dev eth0 | awk '/inet / { split($2,a,"/"); print a[1]; }')}"

# The IP address of the node.  If no IP address is given on the kernel
# command-line, the IP address of the current host is used.
node_ip_addr="${CONF_NODE_IP_ADDR:-$(/sbin/ip addr show dev eth0 | awk '/inet / { split($2,a,"/"); print a[1]; }')}"

broker && ip_addr="$broker_ip_addr"
ip_addr=${ip_addr:-$node_ip_addr}

# The nameservers to which named on the broker will forward requests.
# This should be a list of IP addresses with a semicolon after each.
nameservers="$(awk '/nameserver/ { printf "%s; ", $2 }' /etc/resolv.conf)"


########################################################################

#
# Execute the high-level steps to install a broker or node.
#

if [[ ! x$CONF_NO_NTP =~ x(1|true) ]]
then
  synchronize_clock
fi

if [[ ! x$CONF_NO_SSH_KEYS =~ x(1|true) ]]
then
  install_ssh_keys
fi

#configure_rhel_repo
broker && configure_broker_repo
node && configure_node_repo
node && configure_jboss_cartridge_repo
configure_client_tools_repo

yum update -y

broker && configure_named

broker && update_resolv_conf_on_broker
node && update_resolv_conf_on_node

configure_network

broker && configure_datastore

#broker && configure_qpid
broker && configure_activemq

#broker && configure_mcollective_for_qpid_on_broker
broker && configure_mcollective_for_activemq_on_broker

#node && configure_mcollective_for_qpid_on_node
node && configure_mcollective_for_activemq_on_node

broker && install_broker_pkgs
node && install_node_pkgs
node && install_cartridges
install_rhc_pkg

broker && enable_services_on_broker
node && enable_services_on_node

node && configure_pam_on_node
node && configure_cgroups_on_node

broker && configure_selinux_policy_on_broker
node && configure_selinux_policy_on_node

node && configure_sysctl_on_node
node && configure_sshd_on_node

broker && configure_controller
broker && configure_auth_plugin
broker && configure_messaging_plugin
broker && configure_dns_plugin
broker && configure_httpd_auth
broker && configure_mongo_password

node && configure_port_proxy
node && configure_node
node && update_openshift_facts_on_node

