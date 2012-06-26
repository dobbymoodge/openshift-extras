Summary:        rhsm-register
Name:           rhsm-register
Version:        0.0.2
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
RHSM

cp rhsm-register %{buildroot}/etc/init.d

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
/etc/init.d/rhsm-register

%changelog
* Tue Jun 26 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.2-1
- new package built with tito

