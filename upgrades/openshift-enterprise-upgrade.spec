Name:      openshift-enterprise-upgrade
# The number of the upgrade that is *performed* by moving to this version,
# starting with 1 for 1.1 => 1.2
# Set this to one lower for the pre-upgrade package
%global upgrade_number 1

# items that will likely be shared between RPMs
Version:   1.2
Release:   1%{?dist}
License:   ASL 2.0
URL:       http://openshift.redhat.com
BuildArch: noarch
Provides:  %{name}
Source0:   %{name}-%{version}.tar.gz

%global brokerdir %{_var}/www/openshift/broker
%global etc_upgrade /etc/openshift/upgrade

# native ruby for 1.1
%global upgrade_path /usr/lib/ruby/site_ruby/1.8

# scl ruby for 1.2
%global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective
%global upgrade_path_19 /opt/rh/ruby193/root/usr/local/share/ruby/site_ruby


# items that have to be specified for each RPM
Summary:   Version and upgrade capabilities for OpenShift Enterprise installations
Group:     Network/Daemons
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
This package contains mechanisms for upgrading an OpenShift Enterprise installation.
This RPM need not be built, however.

#############################
%prep
%setup -q

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{mco_root}/agent/
cp mcollective/agent/oseupgrade.* %{buildroot}%{mco_root}/agent/

# ruby libs and bin
mkdir -p %{buildroot}%upgrade_path
cp -r lib/* %{buildroot}%upgrade_path
mkdir -p %{buildroot}%_bindir
cp bin/ose-upgrade %{buildroot}%_bindir

# once we are doing gear migrations we are in ruby193 land
mkdir -p %buildroot%upgrade_path_19/ose-upgrade
cp -r %buildroot%upgrade_path/ose-upgrade/node %buildroot%upgrade_path_19/ose-upgrade/

# create upgrade state file with this version
mkdir -p %{buildroot}%etc_upgrade
touch %buildroot%etc_upgrade/state.yaml
# and log file
mkdir -p %buildroot/var/log/openshift/upgrade.log
touch %buildroot/var/log/openshift/upgrade.log

# create the version file
mkdir -p %buildroot%etc
touch %buildroot%etc/openshift-enterprise-version

%clean
rm -rf $RPM_BUILD_ROOT


############################# version ###############################
%package -n openshift-enterprise-version

# items that have to be specified for each RPM
Summary:   Version and upgrade capabilities for OpenShift Enterprise installations
Group:     Network/Daemons
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description -n openshift-enterprise-version
This package contains mechanisms for upgrading an OpenShift Enterprise installation.

#############################
%files -n openshift-enterprise-version
%defattr(644,root,root,700)
%dir %etc_upgrade
%ghost %etc_upgrade/state.yaml
%ghost /var/log/openshift/upgrade.log
# for some reason the build requires the explicit %attr below
%attr(644,-,-) %ghost /etc/openshift-enterprise-version

# mcollective ddl file is required for both client and agent
%mco_root/agent/oseupgrade.ddl
%upgrade_path/ose-upgrade.rb
%upgrade_path/ose-upgrade/finder.rb
%upgrade_path/ose-upgrade/main.rb

%defattr(0500,root,root,700)
%_bindir/ose-upgrade
%upgrade_path/ose-upgrade/host/

#############################
%post -n openshift-enterprise-version

# If the version file doesn't exist, this is a new installation, so create it.
# Otherwise, leave as-is for the upgrade to handle.
vfile=/etc/openshift-enterprise-version
if [ ! -f $vfile ]; then
  # create the initial version file
  echo "OpenShift Enterprise %version" > $vfile
  chmod 644 $vfile
fi
# same for the upgrade state file.
if [ ! -f %etc_upgrade/state.yaml ]; then
  ose-upgrade --complete %upgrade_number >& /dev/null
fi

############################# broker ###############################
%package broker
Summary:   Upgrade capabilities for OpenShift Enterprise brokers and installations
Group:     Network/Daemons
Requires:  openshift-origin-broker-util
Requires:  openshift-origin-broker
Requires:  openshift-enterprise-version >= %version

%description broker

This contains mechanisms for upgrading an OpenShift Enterprise broker host,
and through it, an entire installation.

#############################
%files broker
%defattr(0500,root,root,700)
%upgrade_path/ose-upgrade/broker
%upgrade_path/ose-upgrade/broker.rb

############################## node ################################
%package node
Summary:   Upgrade capabilities for OpenShift Enterprise node hosts
Group:     Network/Daemons
Requires:  openshift-origin-node-util
Requires:  rubygem-openshift-origin-node
Requires:  openshift-enterprise-version >= %version
%description node

This contains mechanisms for upgrading an OpenShift Enterprise node host.

#############################
%files node
%attr(644,root,root) %mco_root/agent/oseupgrade.rb
%defattr(700,root,root,700)
%upgrade_path/ose-upgrade/node
%upgrade_path/ose-upgrade/node.rb
# once we are doing gear migrations we are in ruby193 land
%upgrade_path_19/ose-upgrade/node



%changelog
* Tue May 28 2013 Luke Meyer <lmeyer@redhat.com> 1.0.0-1
- new package built with tito


