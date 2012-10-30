#!/bin/sh

CONF_PREFIX="${CONF_PREFIX:-demo}"
CONF_DATASTORE_HOSTNAME="mongo.${CONF_PREFIX}.cloudydemo.com"
CONF_ACTIVEMQ_HOSTNAME="activemq.${CONF_PREFIX}.cloudydemo.com"
CONF_NODE_HOSTNAME="node.${CONF_PREFIX}.cloudydemo.com"
CONF_BROKER_HOSTNAME="broker.${CONF_PREFIX}.cloudydemo.com"
CONF_NAMED_HOSTNAME="ns.${CONF_PREFIX}.cloudydemo.com"
CONF_DOMAIN="apps.${CONF_PREFIX}.cloudydemo.com"

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
  # In order for the %post section to succeed, it must have a way of installing from RHEL.
  # The post section cannot access the method that was used in the base install.
  # So, you must subscribe to RHEL or configure RHEL repos here.

  # configure RHEL subscription or repos here

}

configure_client_tools_repo()
{
  # Enable repo with the puddle for broker packages.
  cat > /etc/yum.repos.d/openshift-client.repo <<YUM
[openshift_client]
name=OpenShift Client
baseurl=${repos_base}/Client/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false
sslverify=false

YUM
}

configure_broker_repo()
{
  # Enable repo with the puddle for broker packages.
  cat > /etc/yum.repos.d/openshift-infrastructure.repo <<YUM
[openshift_infrastructure]
name=OpenShift Infrastructure
baseurl=${repos_base}/Infrastructure/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false
sslverify=false

YUM
}

configure_node_repo()
{
  # Enable repo with the puddle for node packages.
  cat > /etc/yum.repos.d/openshift-node.repo <<YUM
[openshift_node]
name=OpenShift Node
baseurl=${repos_base}/Node/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false
sslverify=false

YUM
}

configure_jbosseap_cartridge_repo()
{
  # Enable repo with the puddle for the JBossEAP cartridge package.
  cat > /etc/yum.repos.d/openshift-jboss.repo <<YUM
[openshift_jbosseap]
name=OpenShift JBossEAP
baseurl=${repos_base}/JBoss_EAP6_Cartridge/x86_64/os/
enabled=1
gpgcheck=0
sslverify=false
sslverify=false

YUM
}

configure_jbosseap_subscription()
{
  # The JBossEAP cartridge depends on Red Hat's JBoss packages, so you must
  # subscribe to the appropriate channel here.

  # configure JBossEAP subscription
}

configure_jbossews_subscription()
{
  # The JBossEWS cartridge depends on Red Hat's JBoss packages, so you must
  # subscribe to the appropriate channel here.

  # configure JBossEWS subscription
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
  # We use semanage in this kickstart script, so we need to install
  # policycoreutils-python.
  pkgs="$pkgs policycoreutils-python"

  yum install -y $pkgs
}

# Install any cartridges developers may want.
install_cartridges()
{
  :
  # Following are cartridge rpms that one may want to install here:

  # Embedded cron support. This is required on node hosts.
  carts="openshift-origin-cartridge-cron-1.4"

  # diy app.
  carts="$carts openshift-origin-cartridge-diy-0.1"

  # haproxy-1.4 support.
  carts="$carts openshift-origin-cartridge-haproxy-1.4"

  # JBossEWS1.0 support.
  # Note: Be sure to subscribe to the JBossEWS entitlements during the
  # base install or in configure_jbossews_subscription.
  #carts="$carts openshift-origin-cartridge-jbossews-1.0"

  # JBossEAP6.0 support.
  # Note: Be sure to subscribe to the JBossEAP entitlements during the
  # base install or in configure_jbosseap_subscription.
  #carts="$carts openshift-origin-cartridge-jbosseap-6.0"

  # Jenkins server for continuous integration.
  carts="$carts openshift-origin-cartridge-jenkins-1.4"

  # Embedded jenkins client.
  carts="$carts openshift-origin-cartridge-jenkins-client-1.4"

  # Embedded MySQL.
  carts="$carts openshift-origin-cartridge-mysql-5.1"

  # mod_perl support.
  carts="$carts openshift-origin-cartridge-perl-5.10"

  # PHP 5.3 support.
  carts="$carts openshift-origin-cartridge-php-5.3"

  # Embedded PostgreSQL.
  carts="$carts openshift-origin-cartridge-postgresql-8.4"

  # Python 2.6 support.
  carts="$carts openshift-origin-cartridge-python-2.6"

  # Ruby Rack support running on Phusion Passenger (Ruby 1.8).
  #carts="$carts openshift-origin-cartridge-ruby-1.8"

  # Ruby Rack support running on Phusion Passenger (Ruby 1.9).
  #carts="$carts openshift-origin-cartridge-ruby-1.9"

  # Keep things from breaking too much when testing packaging.
  #carts="$carts --skip-broken"

  yum install -y $carts
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

    # Allow the broker to communicate with the named service.
    echo boolean -m --on allow_ypbind

    # Allow the console to spawn passenger threads
    echo boolean -m --on httpd_execmem
  ) | semanage -i -

  fixfiles -R rubygem-passenger restore
  fixfiles -R mod_passenger restore

  restorecon -R -v /var/run
  restorecon -rv /usr/share/rubygems/gems/passenger-* 
}

# Fix up SELinux policy on the node.
configure_selinux_policy_on_node()
{
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
  restorecon -rv /usr/share/rubygems/gems/passenger-* 
  restorecon -rv /usr/sbin/mcollectived /var/log/mcollective.log /var/run/mcollectived.pid
  restorecon -rv /var/lib/openshift /etc/openshift/node.conf /etc/httpd/conf.d/openshift
}

configure_pam_on_node()
{
  sed -i -e 's|pam_selinux|pam_openshift|g' /etc/pam.d/sshd

  for f in "runuser" "runuser-l" "sshd" "su" "system-auth-ac"
  do
    t="/etc/pam.d/$f"
    if ! grep -q "pam_namespace.so" "$t"
    then
      echo -e "session\t\trequired\tpam_namespace.so no_unmount_on_close" >> "$t"
    fi
  done
}

configure_cgroups_on_node()
{
  cp -vf /usr/share/doc/*/cgconfig.conf /etc/cgconfig.conf
  restorecon -v /etc/cgconfig.conf
  mkdir /cgroup
  restorecon -v /cgroup
  chkconfig cgconfig on
  chkconfig cgred on
  chkconfig openshift-cgroups on
}

configure_quotas_on_node()
{
  # Get the device for /var/lib/openshift.
  geardata_dev="$(df /var/lib/openshift |grep -om1 '/[^[:blank:]]*')"

  # Get the mountpoint for /var/lib/openshift (should be /).
  geardata_mnt="$(awk "/${geardata_dev////\/}/ {print \$2}" < /etc/fstab)"

  if ! [ x"$geardata_dev" != x ] || ! [ x"$geardata_mnt" != x ]
  then
    echo 'Could not enable quotas for gear data:'
    echo 'unable to determine device and mountpoint.'
  else
    # Enable user quotas for the device housing /var/lib/openshift.
    sed -i -e "/^${geardata_dev////\/}[[:blank:]]/{/usrquota/! s/[[:blank:]]\\+/,usrquota&/4;}" /etc/fstab

    # Remount to get quotas enabled immediately.
    mount -o remount "${geardata_mnt}"

    # Generate user quota info for the mount point.
    quotacheck -cmug "${geardata_mnt}"
  fi
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

  # Iff mongod is running on a separate host from the broker, open up
  # the firewall to allow the broker host to connect.
  if broker
  then
    echo 'The broker and data store are on the same host.'
    echo 'Skipping firewall and mongod configuration;'
    echo 'mongod will only be accessible over localhost).'
  else
    echo 'The broker and data store are on separate hosts.'

    echo 'Configuring the firewall to allow connections to mongod...'
    lokkit --nostart --port=27017:tcp

    echo 'Configuring mongod to listen on external interfaces...'
    perl -p -i -e "s/^bind_ip = .*$/bind_ip = 0.0.0.0/" /etc/mongodb.conf
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

configure_gears()
{
  # Make sure that gears are restarted on reboot.
  chkconfig openshift-gears on
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
  chkconfig oddjobd on
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
plugin.qpid.host = ${broker_hostname}
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
plugin.qpid.host = ${broker_hostname}
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
plugin.stomp.host = ${activemq_hostname}
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
registerinterval = 30

# Plugins
securityprovider = psk
plugin.psk = unset

connector = stomp
plugin.stomp.host = ${activemq_hostname}
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
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="${activemq_hostname}" dataDirectory="\${activemq.data}">

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


# Configure qpid. Deprecated for ActiveMQ.
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


  nsdb=/var/named/dynamic/${domain}.db
  cat <<EOF > $nsdb
\$ORIGIN .
\$TTL 1	; 1 seconds (for testing only)
${domain}		IN SOA	${named_hostname}. hostmaster.${domain}. (
				2011112904 ; serial
				60         ; refresh (1 minute)
				15         ; retry (15 seconds)
				1800       ; expire (30 minutes)
				10         ; minimum (10 seconds)
				)
			NS	${named_hostname}.
			MX	10 mail.${domain}.
\$ORIGIN ${domain}.
${named_hostname%.${domain}}			A	${named_ip_addr}
EOF
  # for any other components installed locally, create A records
  broker && echo "${broker_hostname%.${domain}}			A	${broker_ip_addr}" >> $nsdb
  node && echo "${node_hostname%.${domain}}			A	${node_ip_addr}${nl}" >> $nsdb
  activemq && echo "${activemq_hostname%.${domain}}			A	${cur_ip_addr}${nl}" >> $nsdb
  datastore && echo "${datastore_hostname%.${domain}}			A	${cur_ip_addr}${nl}" >> $nsdb
  echo >> $nsdb

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
}


# Make resolv.conf point to our named service, which will resolve the
# host names used in this installation of OpenShift.  Our named service
# will forward other requests to some other DNS servers.
update_resolv_conf()
{
  # Update resolv.conf to use our named.
  #
  # We will keep any existing entries so that we have fallbacks that
  # will resolve public addresses even when our private named is
  # nonfunctional.  However, our private named must appear first in
  # order for hostnames private to our OpenShift PaaS to resolve.
  sed -i -e "1i# The named we install for our OpenShift PaaS must appear first.\\nnameserver ${named_ip_addr}\\n" /etc/resolv.conf
}


# Update the controller configuration.
configure_controller()
{
  # Generate a random salt for the broker authentication.
  broker_auth_salt="$(openssl rand -base64 20)"

  # Configure the broker with the correct hostname, and use random salt
  # to the data store (the host running MongoDB).
  sed -i -e "s/^CLOUD_DOMAIN=.*$/CLOUD_DOMAIN=${domain}/;
             s/^AUTH_SALT=.*/AUTH_SALT=\"${broker_auth_salt}\"/" \
      /etc/openshift/broker.conf

  if !datastore
  then
    #mongo not installed locally, so point to given hostname
    sed -i -e "s/^MONGO_HOST_PORT=.*$/MONGO_HOST_PORT=\"${datastore_hostname}:27017\"/" /etc/openshift/broker.conf
  fi

  # If you change the MongoDB password of "mooo" to something else, be
  # sure to edit and enable the following line:
  #sed -i -e '/MONGO_PASSWORD/s/mooo/<password>/' /etc/openshift/broker.conf

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
BIND_SERVER="${named_ip_addr}"
BIND_PORT=53
BIND_KEYNAME="${domain}"
BIND_KEYVALUE="${KEY}"
BIND_ZONE="${domain}"
EOF

  if named
  then
    echo 'Broker and bind are running on the same host - installing custom SELinux policy'
    pushd /usr/share/selinux/packages/rubygem-openshift-origin-dns-bind/ && make -f /usr/share/selinux/devel/Makefile ; popd
    semodule -i /usr/share/selinux/packages/rubygem-openshift-origin-dns-bind/dhcpnamedforward.pp
  fi
}

# Configure httpd for authentication.
configure_httpd_auth()
{
  # Install the Apache configuration file.
  cp /var/www/openshift/broker/httpd/conf.d/openshift-origin-auth-remote-user-basic.conf.sample \
     /var/www/openshift/broker/httpd/conf.d/openshift-origin-auth-remote-user.conf

  # The above configuration file configures Apache to use
  # /etc/openshift/htpasswd for its password file.  Use the following
  # command to add users:
  #
  #  htpasswd -c /etc/openshift/htpasswd username
  #
  # Here we create a test user
  htpasswd -bc /etc/openshift/htpasswd demo changeme

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

prepend domain-name-servers ${named_ip_addr};
supersede host-name "${hostname}";
supersede domain-name "${domain}";
EOF
}

# Set the hostname
configure_hostname()
{
  sed -i -e "s/HOSTNAME=.*/HOSTNAME=${hostname}/" /etc/sysconfig/network
  hostname "${hostname}"
}

# Set some parameters in the OpenShift node configuration file.
configure_node()
{
  sed -i -e "s/^PUBLIC_IP=.*$/PUBLIC_IP=${node_ip_addr}/;
             s/^CLOUD_DOMAIN=.*$/CLOUD_DOMAIN=${domain}/;
             s/^PUBLIC_HOSTNAME=.*$/PUBLIC_HOSTNAME=${hostname}/;
             s/^BROKER_HOST=.*$/BROKER_HOST=${broker_ip_addr}/" \
      /etc/openshift/node.conf
}

# Run the cronjob installed by openshift-origin-msg-node-mcollective immediately
# to regenerate facts.yaml.
update_openshift_facts_on_node()
{
  /etc/cron.minutely/openshift-facts
}

echo_installation_intentions()
{
  echo "The following components should be installed:"
  for component in $components
  do
    if eval $component
    then
      printf '\t%s.\n' $component
    fi
  done

  echo "Configuring with broker with hostname ${broker_hostname}."
  node && echo "Configuring node with hostname ${node_hostname}."
  echo "Configuring with named with IP address ${named_ip_addr}."
  broker && echo "Configuring with datastore with hostname ${datastore_hostname}."
  echo "Configuring with activemq with hostname ${activemq_hostname}."
}

# Modify console message to show install info
configure_console_msg()
{
  # add the IP to /etc/issue for convenience
  echo "Install-time IP address: ${cur_ip_addr}" >> /etc/issue
  echo_installation_intentions >> /etc/issue
  echo "Check /root/anaconda-post.log to see the %post output." >> /etc/issue
  echo >> /etc/issue
}



########################################################################

#
# Parse the kernel command-line, define variables with the parameters
# specified on it, and define functions broker() and node(), which
# return true or false as appropriate based on whether we are
# configuring the host as a broker or as a node.
#

# Parse /proc/cmdline so that from, e.g., "foo=bar baz" we get
# CONF_FOO=bar and CONF_BAZ=true in the environment.
for word in $(cat /proc/cmdline)
do
  key="${word%%\=*}"
  case "$word" in
    (*=*) val="${word#*\=}" ;;
    (*) val=true ;;
  esac
  eval "CONF_${key^^}"'="$val"'
done

is_true()
{
  for arg
  do
    [[ x$arg =~ x(1|true) ]] || return 1
  done

  return 0
}

is_false()
{
  for arg
  do
    [[ x$arg =~ x(1|true) ]] || return 0
  done

  return 1
}

# Following are the different components that can be installed:
components='broker node named activemq datastore'

# For each component, will define a constant function that return either
# true or false.  For example, there will be a named function.  We can
# then use 'if named; then ...; fi' or just 'named && ...' to run the
# given commands if, and only if, named is enabled.

# By default, each component is _not_ installed.
for component in $components
do
  eval "$component() { false; }"
done

# But any or all components may be explicity enabled.
for component in ${CONF_INSTALL_COMPONENTS//,/ }
do
  eval "$component() { :; }"
done

# If nothing is explicitly enabled, enable everything.
installing_something=0
for component in $components
do
  if eval $component
  then
    installing_something=1
    break
  fi
done
if [ $installing_something = 0 ]
then
  for component in $components
  do
    eval "$component() { :; }"
  done
fi

# Following are some settings used in subsequent steps.

# Where to find the OpenShift repositories; just the base part before
# splitting out into Infrastructure/Node/etc.
repos_base_default='https://mirror.openshift.com/pub/origin-server/nightly/enterprise/2012-10-23'
repos_base="${CONF_REPOS_BASE:-${repos_base_default}}"

# The domain name for the OpenShift Enterprise installation.
domain="${CONF_DOMAIN:-example.com}"

# hostnames to use for the components (could all resolve to same host)
broker_hostname="${CONF_BROKER_HOSTNAME:-broker.${domain}}"
node_hostname="${CONF_NODE_HOSTNAME:-node.${domain}}"
named_hostname="${CONF_NAMED_HOSTNAME:-ns1.${domain}}"
activemq_hostname="${CONF_ACTIVEMQ_HOSTNAME:-activemq.${domain}}"
datastore_hostname="${CONF_DATASTORE_HOSTNAME:-datastore.${domain}}"

# The hostname name for this host.
# Note: If this host is, e.g., both a broker and a datastore, we want to
# go with the broker hostname and not the datastore hostname.
if broker
then hostname="$broker_hostname"
elif node
then hostname="$node_hostname"
elif named
then hostname="$named_hostname"
elif activemq
then hostname="$activemq_hostname"
elif datastore
then hostname="$datastore_hostname"
fi

# Grab the IP address set during installation.
cur_ip_addr="$(/sbin/ip addr show dev eth0 | awk '/inet / { split($2,a,"/"); print a[1]; }')"

# Unless otherwise specified, the broker is assumed to be the current
# host.
broker_ip_addr="${CONF_BROKER_IP_ADDR:-$cur_ip_addr}"

# Unless otherwise specified, the node is assumed to be the current
# host.
node_ip_addr="${CONF_NODE_IP_ADDR:-$cur_ip_addr}"

# Unless otherwise specified, the named service, data store, and
# ActiveMQ service are assumed to be the current host if we are
# installing the component now or the broker host otherwise.
if named
then
  named_ip_addr="${CONF_NAMED_IP_ADDR:-$cur_ip_addr}"
else
  named_ip_addr="${CONF_NAMED_IP_ADDR:-$broker_ip_addr}"
fi

# The nameservers to which named on the broker will forward requests.
# This should be a list of IP addresses with a semicolon after each.
nameservers="$(awk '/nameserver/ { printf "%s; ", $2 }' /etc/resolv.conf)"


########################################################################

echo_installation_intentions

is_false "$CONF_NO_NTP" && synchronize_clock
is_false "$CONF_NO_SSH_KEYS" && install_ssh_keys

#configure_rhel_repo
if activemq || broker || datastore
then
  configure_broker_repo
fi
node && configure_node_repo
node && configure_jbosseap_cartridge_repo
node && configure_jbosseap_subscription
node && configure_jbossews_subscription
broker && configure_client_tools_repo

yum update -y

named && configure_named

#update_resolv_conf

configure_network
#configure_hostname

datastore && configure_datastore

#broker && configure_qpid
activemq && configure_activemq

#broker && configure_mcollective_for_qpid_on_broker
broker && configure_mcollective_for_activemq_on_broker

#node && configure_mcollective_for_qpid_on_node
node && configure_mcollective_for_activemq_on_node

broker && install_broker_pkgs
node && install_node_pkgs
node && install_cartridges
broker && install_rhc_pkg

broker && enable_services_on_broker
node && enable_services_on_node

node && configure_pam_on_node
node && configure_cgroups_on_node
node && configure_quotas_on_node

broker && configure_selinux_policy_on_broker
node && configure_selinux_policy_on_node

node && configure_sysctl_on_node
node && configure_sshd_on_node

broker && configure_controller
broker && configure_auth_plugin
broker && configure_messaging_plugin
broker && configure_dns_plugin
broker && configure_httpd_auth

datastore && configure_mongo_password

node && configure_port_proxy
node && configure_gears
node && configure_node
node && update_openshift_facts_on_node


# Configure an authorized key to provide the broker access
configure_authorized_key()
{
cat <<EOF >> /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDj4ywobxQXlb4ey+2NufOh9+W2BH5NS9a4+D4X7AaKSrgMfTr8P2YFsioFOXXcpjKZrC3HLb6T8ZBxbO5mnTfl9SVv9/gAZZulxXWH/+1P0OLmZQ6u/D0GK4zosRS278Benm6FgiRZSrJZlo+h4Lf4HxAogdiwCDVJs44HnwMWuEjgkOgI0RyQ7txdaZDrwqn8vZ1yh+9bW0HlJWm374lyoNbCJzTH0IQQCLMEnb7QsWzD7lgaNpnKoZeJjQFi0HDGluJt/P9NjyJg3pqnMrGOCkxPU1zT90s0yCGkSUQ1xTJciBQOdffSQj7BAKGSqZxpM2iH8fZUPrpnUxQaXTRh
EOF
}

# Configure the private key on the broker to have named access
configure_private_key()
{
cat <<EOF > /root/.ssh/named_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA4+MsKG8UF5W+HsvtjbnzoffltgR+TUvWuPg+F+wGikq4DH06
/D9mBbIqBTl13KYymawtxy2+k/GQcWzuZp035fUlb/f4AGWbpcV1h//tT9Di5mUO
rvw9BiuM6LEUtu/AXp5uhYIkWUqyWZaPoeC3+B8QKIHYsAg1SbOOB58DFrhI4JDo
CNEckO7cXWmQ68Kp/L2dcofvW1tB5SVpt++JcqDWwic0x9CEEAizBJ2+0LFsw+5Y
GjaZyqGXiY0BYtBwxpbibfz/TY8iYN6apzKxjgpMT1Nc0/dLNMghpElENcUyXIgU
DnX30kI+wQChkqmcaTNoh/H2VD66Z1MUGl00YQIDAQABAoIBAQCkAAz7XFUdVApq
p1/iKvyGh5ytDTbH8dgpbZ1iId3jEDq74jPc7NNDLiDHeb60eHbZ2Oto+Ca62ZGV
z0sSVfqwZ2f12IKF5pnJBv26Thg+5JkmLXwPuj9AfX7+xtGdhZTvgx0Ov8Xg7LzF
dHERkmNTESfTvv5uULnovGtuWKUkZ0d1OJRY4uRFtilEawzeDcs6VCBUSxAKdTgI
p+wH3h2+IOqdMCle7mKt/k3pHDvjVkity3JE1G++m117C5ndUUEoizl9jHzVB0O+
sQaHVLDYZjeLmLS6mHv3EuAK86ZKiZ+kwRehnTnZnrj4tp8l3bZaFLa+thZdCI/E
QD7LoGCxAoGBAPYj8809V/w7mHZ9S7nDcKxvDbQU/Cm3tBW8JVCvFOBPnJbTUaGA
+lKM0Mob2lai6LyvG4RnqpZorQua4Ikb4H5kEti6I0MuVDadOCxLIi6iVSgjX185
hKsvszLEOHXf8BiqkOYbzUCXLdznMVlATNvyzAinJnOyrdaTGziXybfzAoGBAO0E
C1NHtdjVjWB/rCb2f+zKooBNIqo7K6oC6y+YDScgjHw2255w+uCG1sBgiKwHj1kE
lSp/mN0Af03eKshB1wIz5i83PNW2KvV1a2QWkf9ojbw6oPFGZWOOSGpycjJpzrSS
ai7d5fHsVDi7eyEsXNDVht+WjxTXSTdOIMiI8StbAoGBAKfIxi6HvGxiK4HJ007j
3PCOGydAjsvZP9b5E+62CmMFodZmYmTXSMvw1XqQFfusvT2xl+5fxDcXT65zes+7
wwIlMXuvFs56zEkWTu5SoRBs8+OSiTaePMN8lojqnRos9ru5uWBCX13CMC8/IbKX
VE0yascTOfDwQfPc/1dKkOTlAoGBAJxxgPA1cyhuvOSnIQCO0B2CGwTI5Uqrx8Ru
LMK7gGMFLvWGWCwast2k4vcUQOIcE1hUmAj3M/UcMOs6685G9x5zF0qvES6XEX/3
Qy1LYI7Pek51/GmFZ8Lw1Ye9hvcTs+aohgHtYavvrB/OUBWzbIhDiMToYgUFnUQu
A6GaEmXlAoGAJEJ7t+7joQ9TeIoSWlifTWz63biX5B2QLLQeI7ObAjrdj3iDo4De
UAhplvCUbVcZ3aVFYbofhd6Fyh7eR2RdPD/uWcsWeDkaO1lRXLrvTEgvlpFD//SU
EWGodSkqrF8f+Gdj1c7fZdc4XRygiOs/596K118fkehXXYtqs3JyXGs=
-----END RSA PRIVATE KEY-----
EOF

chmod 700 /root/.ssh/named_rsa
}

# Keeps the broker from getting SSH warnings when running the client
configure_permissive_ssh()
{
cat <<EOF >> /etc/ssh/ssh_config

Host *.cloudydemo.com
   CheckHostIP no
   StrictHostKeyChecking no
EOF
}

# Configure a default user
configure_default_user()
{
  htpasswd -b -c /etc/openshift/htpasswd demo changeme
}

# Copy the DNS key from the named host to the broker
set_dns_key()
{
  SSH_CMD="ssh -n -o TCPKeepAlive=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -i /root/.ssh/named_rsa"
  KEY=$(${SSH_CMD} ${named_hostname} "grep Key: /var/named/K${domain}*.private | cut -d ' ' -f 2")
}

# Fix the node configuration to just use the hostname
# Amazon machines have fully qualified hostnames
configure_node_amz()
{
  sed -i -e "s/^PUBLIC_HOSTNAME=.*$/PUBLIC_HOSTNAME=${hostname}/" /etc/openshift/node.conf
}

# Configures named with the correct public IP
configure_named_amz()
{
  # Get the public ip address
  IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

  # Replace the bind configuration with the public ip address
  sed -i -e "s/A 127.0.0.1/A ${IP}/" /var/named/dynamic/${domain}.db
}

# Configures the LIBRA_SERVER variable for convenience
configure_libra_server()
{
  echo "export LIBRA_SERVER='${broker_hostname}'" >> /root/.bashrc
}

# This configures an authorized key to allow the broker to be
# able to obtain the DNS key
named && configure_authorized_key

# This fixes the BIND configuration on the named server by
# setting up the public IP address instead of 127.0.0.1
named && configure_named_amz

# Re-run the DNS plugin configuration after establishing the DNS key.
# Since the DNS key is on the named server, we need to copy it over
# to the broker so it can perform updates.
broker && configure_private_key
broker && set_dns_key
broker && configure_dns_plugin

# This will keep you from getting SSH warnings if you
# are running the client on the broker
broker && configure_permissive_ssh

# This sets up the LIBRA_SERVER on the broker machine
# for convenience of running 'rhc' on it
broker && configure_libra_server

# Setup a default user on the broker (demo / changeme)
broker && configure_default_user

# Re-configure the node hostname for Amazon hosts
node && configure_node_amz

# Important - the callback is only working
# if the file data is sent up.  Probably related
# to the newlines after the initial brace.
cat <<EOF > /tmp/success_data
{
  "Status" : "SUCCESS",
  "Reason" : "Configuration Complete",
  "UniqueId" : "$1",
  "Data" : "Component has completed configuration."
}
EOF

# This calls the verification URL for the CloudFormation
# wait condition.  Again, it's really important to use
# the file format or you will never unblock the wait state.
echo "Calling wait URL..."
curl -T /tmp/success_data $2
echo "Done"

# The kickstart requires the machines to be restarted
# in order to properly start the right services, firewalls,
# etc.  The restart does not re-IP the Amazon machines.
echo "Restarting VM"
reboot
