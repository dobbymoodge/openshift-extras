Summary:        rhsm-register
Name:           rhsm-register
Version:        0.0.4
Release:        1%{?dist}
Group:          Development/System
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rhsm-register-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

%description
Service script for registering/unregistering to the Entitlement Platform

%prep
%setup -q

%build

%post
chkconfig rhsm-register --add

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
mkdir -p %{buildroot}/etc/init.d
mkdir -p %{buildroot}/etc/sysconfig

cat >> %{buildroot}/etc/sysconfig/rhsm-register << RHSM
USERNAME=
PASSWORD=
POOL=
ENABLEREPOS=
RHSM

cp rhsm-register %{buildroot}/etc/init.d

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
/etc/init.d/rhsm-register
%config(noreplace) /etc/sysconfig/rhsm-register

%changelog
* Wed Jun 27 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.4-1
- Minor fix to rhsm-register (bleanhar@redhat.com)
- Adding the ability to enable yum repos (bleanhar@redhat.com)

* Tue Jun 26 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.3-1
- Adding rhsm-register config file (bleanhar@redhat.com)

* Tue Jun 26 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.2-1
- new package built with tito
