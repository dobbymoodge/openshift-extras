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
exclude=rubygem-term-ansicolor rubygem-passenger rubygem-passenger-native rubygem-passenger-native-libs rubygem-stomp
priority=4
EOF

# TODO EPEL ships a broken rubygem-aws-sdk that requires a newer version of rubygem-httparty than exists in EPEL
cat > /etc/yum.repos.d/misc.repo <<EOF
[misc]
name=misc
baseurl=https://mirror.openshift.com/enterprise/enterprise-1.1/misc/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
EOF

cat > /etc/yum.repos.d/devenv.repo <<EOF
[devenv]
name=Devenv repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/enterprise/enterprise-1.1/rhel
        https://mirror2.ops.rhcloud.com/enterprise/enterprise-1.1/rhel
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[devenv-jboss-eap]
name=Devenv EAP repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/enterprise/enterprise-1.1/jb-eap-6-for-rhel-6-server-rpms
        https://mirror2.ops.rhcloud.com/enterprise/enterprise-1.1/jb-eap-6-for-rhel-6-server-rpms
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[devenv-jboss-ews]
name=Devenv EWS repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/enterprise/enterprise-1.1/jb-ews-1-for-rhel-6-server-rpms
        https://mirror2.ops.rhcloud.com/enterprise/enterprise-1.1/jb-ews-1-for-rhel-6-server-rpms
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

[Client]
name=Client repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/enterprise-1.1/openshift_repositories/Client/\$basearch/os/
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
name=Infrastructure repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/enterprise-1.1/openshift_repositories/Infrastructure/\$basearch/os/
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
name=JBoss EAP6 Cartridge repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/enterprise-1.1/openshift_repositories/JBoss_EAP6_Cartridge/\$basearch/os/
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
name=Node repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/enterprise-1.1/openshift_repositories/Node/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=1

EOF
