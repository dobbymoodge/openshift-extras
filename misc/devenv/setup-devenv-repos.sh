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

EOF

cat > /etc/yum.repos.d/devenv.repo <<EOF
[qpid]
name=Qpid repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/libra/qpid/\$basearch/Packages/
        https://mirror2.ops.rhcloud.com/libra/qpid/\$basearch/Packages/
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=https://mirror1.ops.rhcloud.com/libra/li-signing.asc
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem

[passenger]
name=Passenger repo for Enterprise Linux 6
baseurl=https://mirror1.ops.rhcloud.com/libra/passenger
        https://mirror2.ops.rhcloud.com/libra/passenger
failovermethod=priority
enabled=1
gpgcheck=0
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem

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
EOF

cat >> /etc/yum.repos.d/devenv.repo <<EOF
[devenv]
name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/libra/${2-libra-rhel-6.3}-${1-candidate}/\$basearch/
        https://mirror2.ops.rhcloud.com/libra/${2-libra-rhel-6.3}-${1-candidate}/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem

[devenv-source]

name=Li repo for Enterprise Linux 6 - $basearch
baseurl=https://mirror1.ops.rhcloud.com/libra/${2-libra-rhel-6.3}-${1-candidate}/source/SRPMS/
        https://mirror2.ops.rhcloud.com/libra/${2-libra-rhel-6.3}-${1-candidate}/source/SRPMS/
failovermethod=priority
enabled=0
gpgkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-beta
ggpkey=https://mirror1.ops.rhcloud.com/libra/RPM-GPG-KEY-redhat-release
gpgcheck=0
sslverify=0
sslclientcert=/var/lib/yum/client-cert.pem
sslclientkey=/var/lib/yum/client-key.pem
EOF
