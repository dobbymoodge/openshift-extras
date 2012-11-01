#!/bin/bash

cat > /etc/yum.repos.d/epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
baseurl=http://mirror1.ops.rhcloud.com/mirror/epel/6/\$basearch/
        http://mirror2.ops.rhcloud.com/mirror/epel/6/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0

[epel-testing]
name=Extra Packages for Enterprise Linux 6 - Testing - \$basearch
baseurl=http://mirror1.ops.rhcloud.com/mirror/epel/testing/6/\$basearch/
        http://mirror2.ops.rhcloud.com/mirror/epel/testing/6/\$basearch/
failovermethod=priority
enabled=0
gpgcheck=0
priority=5

EOF

cat > /etc/yum.repos.d/devenv.repo <<EOF

[devenv]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/libra/libra-rhel-6.3-candidate/\$basearch/
        https://mirror2.ops.rhcloud.com/libra/libra-rhel-6.3-candidate/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=4
#includepkgs=rh-amazon-rhui-client* scl-utils* rubygem-* ruby193* rsyslog pam* python-* *mongo*


[rhui-us-east-1-rhel-server-releases-i386]
name=Red Hat Enterprise Linux Server 6 -i386 (RPMs)
mirrorlist=https://rhui2-cds01.us-east-1.aws.ce.redhat.com/pulp/mirror/content/dist/rhel/rhui/server/6/\$releasever/i386/os
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-auxiliary
sslverify=1
sslclientkey=/etc/pki/entitlement/content-rhel6.key
sslclientcert=/etc/pki/entitlement/product/content-rhel6.crt
sslcacert=/etc/pki/entitlement/cdn.redhat.com-chain.crt
includepkgs=java-1.6.0-openjdk* java-1.7.0-openjdk*
priority=3

[rhui-us-east-1-rhel-server-releases-optional-i386]
name=Red Hat Enterprise Linux Server 6 Optional -i386 (RPMs)
mirrorlist=https://rhui2-cds01.us-east-1.aws.ce.redhat.com/pulp/mirror/content/dist/rhel/rhui/server/6/\$releasever/i386/optional/os
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-auxiliary
sslverify=1
sslclientkey=/etc/pki/entitlement/content-rhel6.key
sslclientcert=/etc/pki/entitlement/product/content-rhel6.crt
sslcacert=/etc/pki/entitlement/cdn.redhat.com-chain.crt
includepkgs=java-1.6.0-openjdk* java-1.7.0-openjdk*
priority=3


[Client]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/${1-1.0}/rhel-6/Client/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=2

[Infrastructure]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/${1-1.0}/rhel-6/Infrastructure/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=2

[JBoss_EAP6_Cartridge]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/${1-1.0}/rhel-6/JBoss_EAP6_Cartridge/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=2

[Node]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror.openshift.com/enterprise/${1-1.0}/rhel-6/Node/\$basearch/os/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
priority=2

EOF
