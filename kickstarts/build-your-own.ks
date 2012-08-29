# This kickstart script configures a system that acts as both node and
# broker.  Several configuration parameters appear at the top of the
# %post section.
#
# TODO: Comment everything better.
#
# TODO: Either break this kickstart script in two (one for broker and
# one for node) or add conditionals for the parts that are specific to
# one or the other.  For the most part, commands are marked to indicate
# to which of the two they are specific.
#
# XXX: Read parameters (such as node/broker/both) from the kernel
# command-line (see get_cmdline_var below).
#
# TODO: Figure out which commands in %post are unnecessary.
# XXX: Some commands are definitely unnecessary (e.g., some setsebool
# commands that specify settings that are already default).  Should we
# keep these commands?
#
# TODO: Refactor things:
#
#  - yum-install commands in %post should go under %packages (but then
#    do we need redundant repo commands and repository configuration in
#    %post?);
#
#  - packages should include dependencies where reasonable so the
#    dependencies need not be explicitly installed;
#
#  - where possible, configuration should be moved to the relevant
#    packages, or those packages should be changed to facilitate brevity
#    in whatever configuration belongs here;
#
#  - some of the commands in %post might belong in the post-install
#    scripts for specific packages, although we want to avoid opacity in
#    how the broker and nodes ultimately end up in their configured
#    states, we want to avoid weird ordering dependencies in
#    configuration scripts, and we want to avoid creating packages that
#    only exist to perform configuration (e.g., the old
#    openshift-origin-broker and openshift-origin-node packages);
#
#  - and generally, we should use standard kickstart commands wherever
#    possible instead of commands in %post.
#
#version=DEVEL
install
text
skipx

rootpw  --iscrypted $6$QgevUVWY7.dTjKz6$jugejKU4YTngbFpfNlqrPsiE4sLJSj/ahcfqK8fE5lO0jxDhvdg59Qjk9Qn3vNPAUTWXOp9mchQDy6EV9.XBW1

lang en_US.UTF-8
keyboard us
timezone --utc America/New_York

# XXX: We could replace some of the network, firewall, and services
# configuration in %post by tweaks to the following rules.
services --enabled=ypbind,ntpd,network,logwatch
network --onboot yes --device eth0 --hostname node.example.com
firewall --service=ssh
authconfig --enableshadow --passalgo=sha512
selinux --enforcing

# XXX: Should we give OpenShift a higher or lower --cost than base?
# XXX: This doesn't work--apparently, the repo command only makes the
# repositories available during the installation process but does not
# set them up in /etc/yum.repos.d, so we must set the repositories up
# below in %post instead.
#repo --name="Extra Packages for Enterprise Linux 6" --mirrorlist="https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=x86_64"
#repo --name="OpenShift DevOps Alpha" --baseurl="http://download.lab.bos.redhat.com/rel-eng/OpenShift/Alpha/2012-08-09.2/DevOps/x86_64/os/"
#repo --name="OpenShift DevOps Alpha" --baseurl="http://download.lab.bos.redhat.com/rel-eng/OpenShift/Alpha/latest/DevOps/x86_64/os/"

bootloader --location=mbr --driveorder=vda --append=" rhgb crashkernel=auto quiet console=ttyS0"

clearpart --all --initlabel
firstboot --disable
reboot

part /boot --fstype=ext4 --size=500
part pv.253002 --grow --size=1
volgroup vg_vm1 --pesize=4096 pv.253002
logvol / --fstype=ext4 --name=lv_root --vgname=vg_vm1 --grow --size=1024 --maxsize=51200
logvol swap --name=lv_swap --vgname=vg_vm1 --grow --size=2016 --maxsize=4032

%packages
@core
@server-policy
ntp
git
# TODO: Move the yum install commands below up here.

%post --log=/root/anaconda-post.log

# Log the command invocations (and not merely output) in order to make
# the log more useful.
set -x

# Provide a simple way to get settings from the boot command-line.
get_cmdline_var()
{
  sed -e "s/.*\\<${1}=\\([^ ]\\+\\).*/\\1/" /proc/cmdline
}

# Just to test it...
cmdline_LANG="$(get_cmdline_var LANG)"
echo "Got LANG=$cmdline_LANG on the cmdline."

#
# Following are some settings used later on in this script.
#

# The domain name for this OpenShift On-Premise installation.
domain=example.com

# TODO: Parameterize the node (and possibly broker) hostnames as well.

# The IP address of the broker.  We assume here that the current host is
# acting as both broker and node, so the IP address of the broker is the
# IP address of the current host.  If the broker is running on another
# host, substitute its IP address here.
broker_ip_addr="$(/sbin/ip addr show dev eth0 | awk '/inet / { split($2,a, "/") ; print a[1];}')"

# The IP address of the node.
node_ip_addr="$(/sbin/ip addr show dev eth0 | awk '/inet / { split($2,a, "/") ; print a[1];}')"

# The nameservers to which named on the broker will forward requests.
nameservers="$(awk '/nameserver/ { printf "%s; ", $2 }' /etc/resolv.conf)"

########################################################################
# Set up NTP
(
echo "-- NTP --"
date

# Do an initial ntpdate to set the correct time and sync up the hardware
# clock.  Puppet will handle configuring time from now on; this just
# ensures that the time is correct for the first puppetrun.

# Determine our correct NTP server.
# DNS should only return the clocks we can reach.
for clock in $( host clock.corp.redhat.com | awk '{ print $NF }' ); do
    /usr/sbin/ntpdate $clock
done
/sbin/hwclock --systohc
) 2>&1 |tee -ai /root/post_install.log


########################################################################
# Set up SSH.

# TODO: Generate an ssh keypair from libra.pem and check it in.
# XXX: Parameterize the key.
mkdir /root/.ssh
chmod 700 /root/.ssh
cat >> /root/.ssh/authorized_keys << KEYS
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkMc2jArUbWICi0071HXrt5uofQam11duqo5KEDWUZGtHuMTzuoZ0XEtzpqoRSidya9HjbJ5A4qUJBrvLZ07l0OIjENQ0Kvz83alVGFrEzVVUSZyiy6+yM9Ksaa/XAYUwCibfaFFqS9aVpVdY0qwaKrxX1ycTuYgNAw3WUvkHagdG54/79M8BUkat4uNiot0bKg6VLSI1QzNYV6cMJeOzz7WzHrJhbPrgXNKmgnAwIKQOkbATYB+YmDyHpA4m/O020dWDk9vWFmlxHLZqddCVGAXFyQnXoFTszFP4wTVOu1q2MSjtPexujYjTbBBxraKw9vrkE25YZJHvbZKMsNm2b libra_onprem
KEYS


########################################################################
# Set up yum repositories.

# Enable internal RHEL repos (main + extras).
# XXX: Why is this needed? Why doesn't a base installation already have
# /etc/yum.repos.d/redhat.repo or rhel.repo set up?
cat >> /etc/yum.repos.d/rhel.repo << RHEL
[rhel63]
name=rhel63
baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/x86_64/os/
enabled=1
gpgcheck=0

[rhel63-opt]
name=rhel63-opt
baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/optional/x86_64/os/
enabled=1
gpgcheck=0

RHEL

# Enable repo with our build of crankcase.
cat >> /etc/yum.repos.d/openshift_devops.repo << YUM
[openshift_alpha_devops]
# from our alpha brew tag
name=OpenShift DevOps Alpha
#baseurl=http://download.lab.bos.redhat.com/rel-eng/OpenShift/Alpha/latest/DevOps/x86_64/os/
baseurl=http://download.lab.bos.redhat.com/rel-eng/OpenShift/Alpha/2012-08-09.2/DevOps/x86_64/os/
enabled=1
gpgcheck=0

YUM

# Enable the EPEL.
rpm -ivh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm

# Enable the jenkins repo.
#wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
#rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

# Clear out old package listings.
# XXX: Check whether this is still needed.
#yum clean metadata


########################################################################
# Update packages.

yum update -y


########################################################################
# Install stickshift-broker.

yum install stickshift-broker -y #broker

# TODO: These additional packages should be dependencies of the
# stickshift-broker package.  For now, they must be explicitly
# installed.

yum install mcollective -y #broker/node
yum install mcollective-qpid-plugin -y #broker/node
yum install qpid-cpp-server -y #broker/node
yum install rubygem-gearchanger-mcollective-plugin-0.1.7-1.el6_3 -y #broker/?
yum install rubygem-stickshift-node -y #broker/node
yum install rubygem-swingshift-mongo-plugin -y #broker/?
yum install rubygem-uplift-bind-plugin -y #broker/?
yum install stickshift-port-proxy -y #broker/?
#XXX: Why does stickshift-port-proxy depend on procmail?!
yum install stickshift-mcollective-agent -y #broker/?

# Following are cartridge rpms that one may want to install here:

# 10gen MMS agent for performance monitoring of MondoDB.
#yum install cartridge-10gen-mms-agent

# Embedded cron support.
#yum install cartridge-cron-1.4

# diy app.
#yum install cartridge-diy-0.1

# haproxy-1.4 support.
#yum install cartridge-haproxy-1.4

# JBossAS7 support.
#yum install cartridge-jbossas-7

# JBossEAP6.0 support.
#yum install cartridge-jbosseap-6.0

# Jenkins server for continuous integration.
#yum install cartridge-jenkins-1.4

# Embedded jenkins client.
#yum install cartridge-jenkins-client-1.4

# Embedded metrics support.
#yum install cartridge-metrics-0.1

# Embedded MongoDB.
#yum install cartridge-mongodb-2.0

# Embedded MySQL.
#yum install cartridge-mysql-5.1

# NodeJS support.
#yum install cartridge-nodejs-0.6

# mod_perl support.
#yum install cartridge-perl-5.10

# PHP 5.3 support.
#yum install cartridge-php-5.3

# Embedded phpMoAdmin.
#yum install cartridge-phpmoadmin-1.0

# Embedded phpMyAdmin.
#yum install cartridge-phpmyadmin-3.4

# Embedded PostgreSQL.
#yum install cartridge-postgresql-8.4

# Python 2.6 support.
#yum install cartridge-python-2.6

# Embedded RockMongo support.
#yum install cartridge-rockmongo-1.1

# Ruby Rack support running on Phusion Passenger (Ruby 1.8).
#yum install cartridge-ruby-1.8

# Ruby Rack support running on Phusion Passenger (Ruby 1.9).
#yum install cartridge-ruby-1.9


########################################################################
# Fix up SELinux policy.

# TODO: Combine these setsebool commands into a single semanage command
# because each command takes a long time to run.

# Allow the broker to write files in the http file context.
setsebool -P httpd_unified on #broker

# Allow the broker to access the network.
setsebool -P httpd_can_network_connect on #node
setsebool -P httpd_can_network_relay on #node

# Allow the broker to access apps.
setsebool -P httpd_read_user_content on #node
setsebool -P httpd_enable_homedirs on #node

# XXX: The above httpd_* settings are on by default.  Do we need to
# enable them explicitly?

# Allow the broker to configure DNS.
# XXX: This doesn't work, or something disables it later on.
setsebool -P named_write_master_zones on #broker

# Allow ypbind so that the broker can communicate directly with the name
# server.
setsebool -P allow_ypbind on #broker

semodule -i /usr/share/selinux/packages/rubygem-stickshift-common/stickshift.pp \
         -d passenger \
         -i /usr/share/selinux/packages/rubygem-passenger/rubygem-passenger.pp #node

fixfiles -R rubygem-passenger restore #node
fixfiles -R mod_passenger restore #node

restorecon -R -v /var/run #node
restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-* #node
restorecon -r /var/lib/stickshift /etc/stickshift/stickshift-node.conf /etc/httpd/conf.d/stickshift #node
restorecon -r /usr/sbin/mcollectived /var/log/mcollective.log /run/mcollective.pid #node


########################################################################
# Fix up some sysctl knobs.

# Increase kernel semaphores to accomodate many httpds.
echo "kernel.sem = 250  32000 32  4096" >> /etc/sysctl.conf #node

# Move ephemeral port range to accommodate app proxies.
echo "net.ipv4.ip_local_port_range = 15000 35530" >> /etc/sysctl.conf #node

# Increase the connection tracking table size.
echo "net.netfilter.nf_conntrack_max = 1048576" >> /etc/sysctl.conf #node

# Reload sysctl.conf to get the new settings.
# XXX: We could add -e here to ignore errors that are caused by options
# appearing in sysctl.conf that correspond to kernel modules that are
# not yet loaded.  On the other hand, adding -e might cause us to miss
# some important error messages.
sysctl -p /etc/sysctl.conf #node


########################################################################
# Fix up SSH access for developers.

perl -p -i -e "s/^#MaxSessions .*$/MaxSessions 40/" /etc/ssh/sshd_config #node
perl -p -i -e "s/^#MaxStartups .*$/MaxStartups 40/" /etc/ssh/sshd_config #node
echo 'AcceptEnv GIT_SSH' >> /etc/ssh/sshd_config #broker/node
# XXX: Should GIT_SSH be accepted on the broker?
ln -s /usr/bin/sssh /usr/bin/rhcsh #node


########################################################################
# Configure MongoDB.

# Require authentication.
perl -p -i -e "s/^#auth = .*$/auth = true/" /etc/mongodb.conf #node/broker

# Start mongod so we can perform some administration now.
service mongod restart

# The init script is broken as of version 2.0.2-1.el6_3: The start and
# restart actions return before the daemon is ready to accept
# connections (it appears to take time to initialize the journal).  Thus
# we need the following hack to wait until the daemon is ready.
echo "Waiting for MongoDB to start ($(date +%H:%M:%S))..."
while :
do
  echo exit | mongo && break
  sleep 5
done
echo "MongoDB is finally ready! ($(date +%H:%M:%S))"

# Set the password.
# XXX: Parameterize the password.
mongo stickshift_broker_dev --eval 'db.addUser("stickshift", "mooo")'
#sed -i -e '/:password => "mooo"/s/mooo/<password>/' /var/www/stickshift/broker/config/environments/development.rb

# Add user "admin" with password "admin" for ss-register-user and such.
mongo stickshift_broker_dev --eval 'db.auth_user.update({"_id":"admin"}, {"_id":"admin","user":"admin","password":"2a8462d93a13e51387a5e607cbd1139f"}, true)'

# Use a smaller default size for databases.
if [ "x`fgrep smallfiles=true /etc/mongodb.conf`x" != "xsmallfiles=truex" ] ; then
  echo "smallfiles=true" >> /etc/mongodb.conf
fi #broker


########################################################################
# Open up services required for apps and developers.

# We use --nostart below because activating the configuration here will
# produce errors.  Anyway, we only need the configuration activated
# after Anaconda reboots, so --nostart makes sense in any case.

# Open up standard services.
lokkit --nostart --service=ssh #node/broker
lokkit --nostart --service=https #node/broker
lokkit --nostart --service=http #node/broker
lokkit --nostart --service=dns #broker

# Open up ports for app proxies.
lokkit --nostart --port=35531-65535:tcp #node

# Open up ports for qpid.
lokkit --nostart --port=5672:tcp #broker


########################################################################
# Enable services.

chkconfig sshd on #broker/node
chkconfig httpd on #broker/node
chkconfig qpidd on #broker/node
chkconfig mcollective on #broker/node
chkconfig network on #broker/node
chkconfig stickshift-broker on #broker
chkconfig stickshift-proxy on #broker
chkconfig named on #broker
chkconfig mongod on #broker


########################################################################
# Configure mcollective.

cat <<EOF > /etc/mcollective/client.cfg #node/broker
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
plugin.qpid.host=broker.${domain}
plugin.qpid.secure=false
plugin.qpid.timeout=5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF

cat <<EOF > /etc/mcollective/server.cfg #node/broker
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
plugin.qpid.host=broker.${domain}
plugin.qpid.secure=false
plugin.qpid.timeout=5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF


########################################################################
# Configure qpid.

if [[ "x`fgrep auth= /etc/qpidd.conf`" == xauth* ]]
then
  sed -i -e 's/auth=yes/auth=no/' /etc/qpidd.conf
else
  echo "auth=no" >> /etc/qpidd.conf
fi #node/broker


########################################################################
# Configure BIND.

# Generate a new key for the domain.
# XXX: Parameterize the domain.
# XXX: Parameterize the key.
# XXX: Do we use USER or HOST?
# https://openshift.redhat.com/community/wiki/local-dynamic-dns-service#Integrated_Local_DNS_Service
# uses USER, but ss-setup-bind uses HOST.
rm -f /var/named/K${domain}*
pushd /var/named
dnssec-keygen -a HMAC-MD5 -b 512 -n USER ${domain}
KEY="$(grep Key: K${domain}*.private | cut -d ' ' -f 2)"
popd
keyfile=/var/named/${domain}.key

# Ensure we have a key for the broker to communicate with BIND.
# XXX: Do we need the if-then statement? Either the key should always
# be there or it will never be there.
if [ ! -f /etc/rndc.key ]
then
  rndc-confgen -a
fi
restorecon /etc/rndc.* /etc/named.*
chown root:named /etc/rndc.key
chmod 640 /etc/rndc.key

# Set up DNS forwarding.
# XXX: Read from resolv.conf?
cat <<EOF > /var/named/forwarders.conf
forwarders { ${nameservers} } ;
EOF
restorecon /var/named/forwarders.conf
chmod 755 /var/named/forwarders.conf
service named restart

# Update resolv.conf to use the local BIND instance.
# XXX: ss-setup-broker throws in the same DNS servers from
# forwarders.conf, but isn't that redundant?
cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF

# Install the configuration file for the OpenShift On-Premise domain
# name.
rm -rf /var/named/dynamic
mkdir -p /var/named/dynamic
#XXX: Don't hardcode the path name (which includes the version number)!
sed "s/example.com/${domain}/g" < /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-0.8.5/doc/examples/example.com.db > /var/named/dynamic/${domain}.db

# Install the key for the OpenShift On-Premise domain.
# XXX: Don't hardcode the domain name.
cat <<EOF > /var/named/${domain}.key
key ${domain} {
  algorithm HMAC-MD5;
  secret "${KEY}";
};
EOF

# XXX: What does this do? Does BIND check the timestamps?
touch /var/named/data/named.run
touch /var/named/data/queries.log
touch /var/named/data/cache_dump.db
touch /var/named/data/named_stats.txt
touch /var/named/data/named_mem_stats.txt
touch /var/named/forwarders.conf
chown named:named -R /var/named
restorecon -R /var/named

# Update named.conf.
#XXX: Don't hardcode the path name (which includes the version number)!
sed "s/example.com/${domain}/g" < /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-0.8.5/doc/examples/named.conf > /etc/named.conf
chown root:named /etc/named.conf
/usr/bin/chcon system_u:object_r:named_conf_t:s0 -v /etc/named.conf

# Start named so we can perform some updates immediately.
service named restart

# Tell BIND about the broker.
nsupdate -k ${keyfile} <<EOF
server 127.0.0.1
update delete broker.${domain} A
update add broker.${domain} 180 A ${broker_ip_addr}
send
EOF

# Tell BIND about the node.
nsupdate -k ${keyfile} <<EOF
server 127.0.0.1
update delete node.${domain} A
update add node.${domain} 180 A ${node_ip_addr}
send
EOF


########################################################################
# Fix up swingshift plugins configuration (broker).

# Use mongo for authentication.
sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'swingshift-mongo-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/swingshift-mongo-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

# Use BIND for DNS.
sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'uplift-bind-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/uplift-bind-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb
pushd /usr/share/selinux/packages/rubygem-uplift-bind-plugin/ && make -f /usr/share/selinux/devel/Makefile ; popd
semodule -i /usr/share/selinux/packages/rubygem-uplift-bind-plugin/dhcpnamedforward.pp

mkdir -p /var/www/stickshift/broker/config/environments/plugin-config
cat <<EOF > /var/www/stickshift/broker/config/environments/plugin-config/uplift-bind-plugin.rb
Broker::Application.configure do
  config.dns = {
    :server => "127.0.0.1",
    :port => 53,
    :keyname => "${domain}",
    :keyvalue => "${KEY}",
    :zone => "${domain}"
  }
end
EOF
perl -p -i -e "s/.*:domain_suffix.*/    :domain_suffix => \"${domain}\",/" /var/www/stickshift/broker/config/environments/*.rb
# */ # What the heck, VIM syntax highlighting? Kickstart scripts do not use
#  C-style comments.
chown apache:apache /var/www/stickshift/broker/config/environments/plugin-config/uplift-bind-plugin.rb
restorecon /var/www/stickshift/broker/config/environments/plugin-config/uplift-bind-plugin.rb

# Use mcollective for RPC.
sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'gearchanger-mcollective-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/gearchanger-mcollective-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb


########################################################################
# Update network configuration.

# Append some stuff to the DHCP configuration.
cat <<EOF >> /etc/dhcp/dhclient-eth0.conf

prepend domain-name-servers ${broker_ip_addr};
supersede host-name "node";
supersede domain-name "${domain}";
EOF

# XXX: Should we drop the double-quotation marks?
for IF_FILE in /etc/sysconfig/network-scripts/ifcfg-*
do
  sed -i -e '/^NM_CONTROLLED=/ s/"yes"/"no"/' $IF_FILE
done


sed -i -e "s/HOSTNAME=.*/HOSTNAME=node.${domain}/" /etc/sysconfig/network


########################################################################
# Fix up broker configuration.

perl -p -i -e "s/^PUBLIC_IP=.*$/PUBLIC_IP=${broker_ip_addr}/" /etc/stickshift/stickshift-node.conf
perl -p -i -e "s/^CLOUD_DOMAIN=.*$/CLOUD_DOMAIN=${domain}/" /etc/stickshift/stickshift-node.conf
perl -p -i -e "s/^PUBLIC_HOSTNAME=.*$/PUBLIC_HOSTNAME=node.${domain}/" /etc/stickshift/stickshift-node.conf
perl -p -i -e "s/^BROKER_HOST=.*$/BROKER_HOST=${broker_ip_addr}/" /etc/stickshift/stickshift-node.conf


########################################################################
# Run the cronjob installed by stickshift-mcollective-agent immediately
# to regenerate facts.yaml.

#service crond restart
/etc/cron.minutely/stickshift-facts


########################################################################
# Make sure stickshift-proxy is running.

# XXX: This is not really needed during the kickstart.
#service stickshift-proxy restart


########################################################################
# TODO: We should have an irc-bot that posts the IP address of the VM.


%end
