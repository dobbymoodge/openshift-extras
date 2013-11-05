#!/bin/bash

# TODO: We have to get tito from EPEL at the risk of pulling in packages that can taint the build
cat > /etc/yum.repos.d/epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
baseurl=http://mirror1.ops.rhcloud.com/mirror/epel/6/\$basearch/
        http://mirror2.ops.rhcloud.com/mirror/epel/6/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0
EOF

# TODO: We have to get puppet from the PuppetLabs repo at the risk of pulling in packages that can taint the build
cat > /etc/yum.repos.d/puppetlabs-products.repo <<EOF
[puppetlabs-products]
name=Puppet Labs Products - \$basearch
baseurl=http://yum.puppetlabs.com/el/6/products/\$basearch
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
enabled=0
gpgcheck=1
EOF

# TODO EPEL ships a broken rubygem-aws-sdk that requires a newer version of rubygem-httparty than exists in EPEL
cat > /etc/yum.repos.d/misc.repo <<EOF
[misc]
name=misc
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/misc/
failovermethod=priority
enabled=1
priority=4
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
EOF

cat > /etc/yum.repos.d/devenv.repo <<EOF
# This repo is only needed when testing pre-release RHEL content
[devenv]
name=Devenv repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror1.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/rhel
        https://mirror2.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/rhel
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
priority=2
exclude=tomcat6*
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
# We have to be careful that this only shadows the rhui RHEL when we actually need it

# This repo is only needed when testing pre-release JBoss content
#[devenv-jboss-eap]
#name=Devenv EAP repo for Enterprise Linux 6 - \$basearch
#baseurl=https://mirror1.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/jb-eap-6-for-rhel-6-server-rpms
#        https://mirror2.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/jb-eap-6-for-rhel-6-server-rpms
#failovermethod=priority
#enabled=1
#gpgcheck=0
#gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
#ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
#sslverify=0
#sslclientcert=/var/lib/yum/client-cert.pem
#sslclientkey=/var/lib/yum/client-key.pem
#priority=3

# This repo is only needed when testing pre-release JBoss content
#[devenv-jboss-ews]
#name=Devenv EWS repo for Enterprise Linux 6 - \$basearch
#baseurl=https://mirror1.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/jb-ews-2-for-rhel-6-server-rpms
#        https://mirror2.ops.rhcloud.com/enterprise/${1-enterprise-2.0}/jb-ews-2-for-rhel-6-server-rpms
#failovermethod=priority
#enabled=1
#gpgcheck=0
#gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
#ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
#sslverify=0
#sslclientcert=/var/lib/yum/client-cert.pem
#sslclientkey=/var/lib/yum/client-key.pem
#priority=3

[Test_Dependencies]
name=Client repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories_devenv/Test_Dependencies/\$basearch/os/
failovermethod=priority
enabled=1
priority=4
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem

[Test_Dependencies_Libra]
name=Client repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories_devenv/Test_Dependencies_Libra/\$basearch/os/
failovermethod=priority
enabled=1
priority=4
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem

[Client-ruby193]
name=Client repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories_devenv/Client-ruby193/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=4

[Client]
name=Client repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories/RHOSE-CLIENT-2.0/\$basearch/os
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[Infrastructure]
name=Infrastructure repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories/RHOSE-INFRA-2.0/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[JBoss_EAP6_Cartridge]
name=JBoss EAP6 Cartridge repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories/RHOSE-JBOSSEAP-2.0/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[Node]
name=Node repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror.openshift.com/enterprise/${1-enterprise-2.0}/openshift_repositories/RHOSE-NODE-2.0/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[libra]
name=libra repo for Enterprise Linux 6 - \$basearch
baseurl=https://mirror1.ops.rhcloud.com/libra/libra-rhel-6-candidate/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=5

#[rhscl]
#name=rhscl repo for Enterprise Linux 6 - \$basearch
#baseurl=https://mirror1.ops.rhcloud.com/libra/rhscl-1.0-rhel-6/x86_64
#failovermethod=priority
#enabled=1
#gpgcheck=0
#gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
#ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
#sslverify=0
#sslclientcert=/var/lib/yum/client-cert.pem
#sslclientkey=/var/lib/yum/client-key.pem
#priority=1

EOF
