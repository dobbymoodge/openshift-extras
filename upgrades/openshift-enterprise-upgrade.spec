Name:      openshift-enterprise-upgrade
# The number of the upgrade that is *performed* by moving to this version.
# See VERSION_MAP in lib/ose-upgrade/main.rb for the mapping of upgrade
# numbers to OpenShift Enterprise releases.
# Set this to one lower for the pre-upgrade package
%global upgrade_number 2

# items that will likely be shared between RPMs
Version:   2.0.0a
Release:   1%{?dist}
License:   ASL 2.0
URL:       http://openshift.redhat.com
BuildArch: noarch
Provides:  %{name}
Source0:   %{name}-%{version}.tar.gz

%global brokerdir %{_var}/www/openshift/broker
%global etc_upgrade /etc/openshift/upgrade

# OpenShift Enterprise uses the ruby193 software collection since
# the 1.2 release, so we will only use Ruby packages in that collection.
%global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective
%global upgrade_path /opt/rh/ruby193/root/usr/local/share/ruby/site_ruby

# yum-validator locations
%global yumv_lib /usr/lib64/python2.6/site-packages/yumvalidator
%global yumv_etc /etc/yum-validator


# items that have to be specified for each RPM
Summary:   Version and upgrade capabilities for OpenShift Enterprise installations
Group:     Network/Daemons
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
This RPM contains mechanisms for upgrading an OpenShift Enterprise installation.
This RPM need not be built, however.

#############################
%prep
%setup -q

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{mco_root}/agent/
cp mcollective/agent/oseupgrade.* %{buildroot}%{mco_root}/agent/

mkdir -p %{buildroot}%{_libexecdir}/openshift
cp mcollective/gear_upgrade_extension.rb %{buildroot}%{_libexecdir}/openshift/
cp bin/ose-upgrade-migrate-datastore %{buildroot}%{_libexecdir}/openshift/
cp bin/ose-upgrade-gears %{buildroot}%{_libexecdir}/openshift/

mkdir -p %{buildroot}%{_libexecdir}/openshift/check-sources
cp libexec/check-sources/oo-admin-check-sources.py %{buildroot}%{_libexecdir}/openshift/check-sources/
cp libexec/check-sources/check_sources.py %{buildroot}%{_libexecdir}/openshift/check-sources/
cp libexec/check-sources/repo_db.py %{buildroot}%{_libexecdir}/openshift/check-sources/
cp libexec/check-sources/beta2.ini %{buildroot}%{_libexecdir}/openshift/check-sources/

# Ruby libs and bin
mkdir -p %{buildroot}%{upgrade_path}
cp -r lib/* %{buildroot}%{upgrade_path}
rm %{buildroot}%{upgrade_path}/ose-upgrade/README.md
mkdir -p %{buildroot}%{_bindir}
cp bin/ose-upgrade %{buildroot}%{_bindir}

# create upgrade state file with this version
mkdir -p %{buildroot}%{etc_upgrade}
touch %{buildroot}%{etc_upgrade}/state.yaml
# and log file
mkdir -p %{buildroot}/var/log/openshift/upgrade.log
touch %{buildroot}/var/log/openshift/upgrade.log

# create yum-validator locations
cp yum-validator/oo-admin-yum-validator %{buildroot}%_bindir
mkdir -p %{buildroot}%yumv_lib
cp -r yum-validator/yumvalidator/* %{buildroot}%yumv_lib
mkdir -p %{buildroot}%yumv_etc
cp -r yum-validator/etc/* %{buildroot}%yumv_etc

mkdir -p %{buildroot}%{_mandir}/man8/
cp -p yum-validator/man/*.8 %{buildroot}%{_mandir}/man8/

# create the version file
mkdir -p %{buildroot}%{etc}
touch %{buildroot}%{etc}/openshift-enterprise-release

%clean
rm -rf $RPM_BUILD_ROOT


############################# release ###############################
%package -n openshift-enterprise-release

# items that have to be specified for each RPM
Summary:   Version and upgrade capabilities for OpenShift Enterprise installations
Group:     Network/Daemons
Requires:  openshift-enterprise-yum-validator >= %version
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:  ruby

%description -n openshift-enterprise-release
This RPM contains mechanisms for upgrading an OpenShift Enterprise installation.

#############################
%files -n openshift-enterprise-release
%defattr(644,root,root,700)
%dir %{etc_upgrade}
%ghost %{etc_upgrade}/state.yaml
%ghost /var/log/openshift/upgrade.log
# for some reason the build requires the explicit %attr below
%attr(644,-,-) %ghost /etc/openshift-enterprise-release

# mcollective ddl file is required for both client and agent
%{mco_root}/agent/oseupgrade.ddl
%{upgrade_path}/ose-upgrade.rb
%{upgrade_path}/ose-upgrade/finder.rb
%{upgrade_path}/ose-upgrade/main.rb

%defattr(0500,root,root,700)
%{_bindir}/ose-upgrade
%{upgrade_path}/ose-upgrade/host/


#############################
%post -n openshift-enterprise-release

# If the version file doesn't exist, this is a new installation, so create it.
# Otherwise, leave as-is for the upgrade to handle.
vfile=/etc/openshift-enterprise-release
if [ ! -f $vfile ]; then
  # create the initial version file
  echo "OpenShift Enterprise %{version}" > $vfile
  chmod 644 $vfile
fi
# same for the upgrade state file.
if [ ! -f %{etc_upgrade}/state.yaml ]; then
  ose-upgrade --complete %{upgrade_number} >& /dev/null
fi

############################# yum-validator ###############################
%package -n openshift-enterprise-yum-validator
Summary:   Validates and configures yum for OpenShift Enterprise installations and updates
Group:     Network/Daemons
Requires:  yum-utils
Requires:  yum-plugin-priorities

%description -n openshift-enterprise-yum-validator
This RPM supplies the yum-validator for validating and configuring the yum repositories
that OpenShift Enterprise uses for installation and updates. It supports either
subscription-manager or RHN classic as the RPM delivery mechanism.

#############################
%files -n openshift-enterprise-yum-validator
%defattr(644,root,root,700)
%yumv_lib
%yumv_etc
%config(noreplace) %yumv_etc/repos.ini
%config(noreplace) %yumv_etc/beta2.ini
%defattr(0500,root,root,700)
%_bindir/oo-admin-yum-validator
%{_mandir}/man8/oo-admin-yum-validator.8.gz

############################# broker ###############################
%package broker
Summary:   Upgrade capabilities for OpenShift Enterprise brokers and installations
Group:     Network/Daemons
Requires:  openshift-origin-broker-util
Requires:  openshift-origin-broker
Requires:  openshift-enterprise-release >= %version
Requires:  openshift-enterprise-check-sources

%description broker

This contains mechanisms for upgrading an OpenShift Enterprise broker host,
and through it, an entire installation.

#############################
%files broker
%defattr(0500,root,root,700)
%{upgrade_path}/ose-upgrade/broker
%{upgrade_path}/ose-upgrade/broker.rb
%{_libexecdir}/openshift/ose-upgrade-gears
%{_libexecdir}/openshift/ose-upgrade-migrate-datastore

############################## node ################################
%package node
Summary:   Upgrade capabilities for OpenShift Enterprise node hosts
Group:     Network/Daemons
Requires:  openshift-origin-node-util
Requires:  rubygem-openshift-origin-node
Requires:  openshift-enterprise-release >= %{version}
Requires:  openshift-enterprise-check-sources
%description node

This contains mechanisms for upgrading an OpenShift Enterprise node host.

#############################
%files node
%attr(644,root,root) %{mco_root}/agent/oseupgrade.rb
%attr(644,root,root) %{_libexecdir}/openshift/gear_upgrade_extension.rb
%defattr(700,root,root,700)
%{upgrade_path}/ose-upgrade/node
%{upgrade_path}/ose-upgrade/node.rb

########################### check-sources ###########################
%package -n openshift-enterprise-check-sources
Summary:   Tool to check and fix Yum repos or RHN/RHSM channels for OpenShift Enterprise
Group:     Network/Daemons
Requires:  python
%description -n openshift-enterprise-check-sources
This package contains the oo-admin-check-sources.py tool for checking
what Yum repos or RHN/RHSM channels are available and enabled and
setting appropriate priorities to assure that Yum will get packages from
the appropriate sources based on the host's role (broker or node host)
and version of OpenShift Enterprise.

#############################
%files -n openshift-enterprise-check-sources
%defattr(644,root,root,700)
%{_libexecdir}/openshift/check-sources/beta2.ini
%attr(755,root,root) %{_libexecdir}/openshift/check-sources/oo-admin-check-sources.py
# The rpm-build's brp-python-bytecompile script automatically generates
# these bytecode files:
%{_libexecdir}/openshift/check-sources/oo-admin-check-sources.pyc
%{_libexecdir}/openshift/check-sources/oo-admin-check-sources.pyo
%{_libexecdir}/openshift/check-sources/check_sources.py
%{_libexecdir}/openshift/check-sources/check_sources.pyc
%{_libexecdir}/openshift/check-sources/check_sources.pyo
%{_libexecdir}/openshift/check-sources/repo_db.py
%{_libexecdir}/openshift/check-sources/repo_db.pyc
%{_libexecdir}/openshift/check-sources/repo_db.pyo



%changelog
* Fri Nov 22 2013 Brenton Leanhardt <bleanhar@redhat.com> 2.0.0a-1
- Adding the oo-admin-yum-validator manpage from upstream (bleanhar@redhat.com)
- <ose-upgrade> 2.0 upgrade fixes (jdetiber@redhat.com)
- ose-upgrade for RHOSE 2.0 (miciah.masters@gmail.com)

* Mon Nov 18 2013 Luke Meyer <lmeyer@redhat.com> 2.0.0-1
- <o-e-upgrade> update version/release (lmeyer@redhat.com)
- <o-e-upgrade> spec file adjustments (lmeyer@redhat.com)
- <ose-upgrade> does not require rubygems (lmeyer@redhat.com)
- <ose-upgrade> give version number for upgrade 2 (lmeyer@redhat.com)
- <yum-validator> sync to ed3e5605 from openshift-extras (lmeyer@redhat.com)

* Thu Nov 14 2013 Luke Meyer <lmeyer@redhat.com> 2.0-0.beta.2
- <o-e-upgrade> add yum-validator subpackage (lmeyer@redhat.com)

* Wed Jul 24 2013 Brenton Leanhardt <bleanhar@redhat.com> 1.2.1-2
- Bug 988069 - 1.2 upgrade fails when using mongo replica set
  (bleanhar@redhat.com)

* Tue Jul 16 2013 Brenton Leanhardt <bleanhar@redhat.com> 1.2.1-1
- Merge remote-tracking branch 'origin/enterprise-1.2' into enterprise-1.2.z
  (bleanhar@redhat.com)
- Bug 980913 - openshift-enterprise-release does not correctly require ruby and
  rubygems (bleanhar@redhat.com)

* Mon Jul 08 2013 Brenton Leanhardt <bleanhar@redhat.com> 1.2.0-1
- <1.2 upgrade> fix EWS channel name (lmeyer@redhat.com)

* Mon Jul 08 2013 Brenton Leanhardt <bleanhar@redhat.com> 1.2-2
- <1.2 Upgrade> - Fixups for awk-fu (jdetiber@redhat.com)
- <1.2 Upgrade> Fix for setting priorities/excludes on RHN channels
  (jdetiber@redhat.com)

* Wed Jun 26 2013 Jason DeTiberus <jdetiber@redhat.com> 1.3-1
- <migration.rb> Fix malformed error message in self.migrate
  (jolamb@redhat.com)

* Tue Jun 25 2013 Luke Meyer <lmeyer@redhat.com> 1.2-1
- Official release for 1.2

* Tue May 28 2013 Luke Meyer <lmeyer@redhat.com> 1.0.0-1
- new package built with tito


