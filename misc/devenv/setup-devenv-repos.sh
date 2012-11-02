#!/bin/bash

cat > /etc/yum.repos.d/epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
baseurl=http://mirror1.ops.rhcloud.com/mirror/epel/6/\$basearch/
        http://mirror2.ops.rhcloud.com/mirror/epel/6/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=0
includepkgs=perl-Any-Moose perl-Mouse pigz pymongo pymongo-gridfs pyrpkg python-bson python-fedora rubygem-aws-sdk rubygem-uuidtools snappy tito fedora-cert fedora-packager fedpkg koji mock libyubikey bodhi-client
#priority=5
EOF

cat > /etc/yum.repos.d/devenv.repo <<EOF
[devenv]
name=Devenv repo for Enterprise Linux 6 - $basearch
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
includepkgs=GitPython perl-MongoDB python-argparse python-async python-bunch python-gitdb python-kitchen python-offtrac python-smmap python-virtualenv rsyslog rh-amazon-rhui-client* ruby193-build ykpers rubygem-addressable rubygem-httparty rubygem-crack rubygem-webmock php-pecl-mongo ruby193-rubygems-devel
#priority=4

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
#priority=2

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
#priority=2

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
#priority=2

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
#priority=2

EOF
