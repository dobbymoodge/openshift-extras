
# items that will likely be shared between packages
Name:      openshift-enterprise-upgrade
Version:   1.2
Release:   1%{?dist}
License:   ASL 2.0
URL:       http://openshift.redhat.com
BuildArch: noarch
Provides:  %{name}

%define brokerdir %{_var}/www/openshift/broker
%define mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective

# items that have to be specified for each package
Summary:   Upgrade capabilities for OpenShift Enterprise installations
Group:     Network/Daemons
Source0:   %{name}-%{version}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)


%description
This contains mechanisms for upgrading an OpenShift Enterprise broker host,
and through it, an entire installation.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{mco_root}/agent/
cp node/mcollective/agent/upgrade.ddl %{buildroot}%{mco_root}/agent/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0640,-,-) %{mco_root}/agent/*

%post

%changelog

############################# broker ###############################
%package broker
Summary:   Upgrade capabilities for OpenShift Enterprise brokers and installations
Group:     Network/Daemons
Requires:  openshift-origin-broker-util
Requires:  openshift-origin-broker
%description broker

This contains mechanisms for upgrading an OpenShift Enterprise broker host,
and through it, an entire installation.

%files

############################## node ################################
%package node
Summary:   Upgrade capabilities for OpenShift Enterprise node hosts
Group:     Network/Daemons
Requires:  openshift-origin-node-util
Requires:  rubygem-openshift-origin-node
Requires:  openshift-origin-msg-node-mcollective
%description node

This contains mechanisms for upgrading an OpenShift Enterprise node host.

%files

############################# version ##############################
%package -n openshift-enterprise-version
Summary:   Version package for OpenShift Enterprise installations
Group:     Network/Daemons
%description -n openshift-enterprise-version

This contains the version file /etc/openshift-enterprise-release

%files

