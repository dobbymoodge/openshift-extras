#!/usr/bin/ruby
# yeah, i know. a CGI. so old-school it hurts...
# This is a little convenience script for one-step kickstarts with NTP,
# DDNS, and our repos enabled. Makes a few assumptions about its env
# right now... just recording it here for the moment.
# Currently running at:
# http://buildvm-devops.usersys.redhat.com/ks/

require 'cgi'

#### globals ####
build = {
	'alpha' => ['devops_alpha', 'http://download.lab.bos.redhat.com/rel-eng/OpenShift/Alpha/latest/DevOps/x86_64/os/'],
}
spin = {
	'base' => "",
	'broker' => "cartridge-*\nopenshift-origin-broker",
	'node' => "cartridge-*\nopenshift-origin-node",
	'combo' => "cartridge-*\nopenshift-origin-node\nopenshift-origin-broker",
	}

cgi = CGI.new
params = cgi.params
path = cgi.path_info

def sanitize(str, nix)
  return nil if str.nil?
  sane = str.gsub( nix, "")
  sane.empty? ? nil : sane
end

def sanitize_host(host)
  sanitize host, /[^a-z0-9-]/i 
end

def sanitize_hash(hash)
  sanitize hash, /[^a-f0-9]/i
end

if params.empty? && path == '/' 
  # print the instruction page
  puts cgi.header
  puts <<FORM
<!doctype html>
<html lang="en"><body><form method="post">
<h2>Instant custom DevOps kickstart</h2>
    <select name="build">
	<option value="alpha">Alpha</option>
    </select>
    <select name="spin">
	<option value="base">Base OS install</option>
	<option value="broker">Broker install</option>
	<option value="node">Node install</option>
	<option value="combo" selected="1">Broker+node install</option>
    </select>
    <h3>Dynamic DNS</h3>
    To enable dynamic DNS, <a href="https://hdn.corp.redhat.com/redhat-ddns/admin/" target="_blank">create a hostname</a>
    and enter the following values:
    <br>
    Host name: <input name="host"> Hash: <input name="hash">
    <br>
    <input type="submit" value="Make KS file">
</form></body></html
FORM

elsif path.nil? || path == '/' 
  #############################################################
  # print the info for how to use the ks with these params
  this_build, this_spin = params['build'][0],params['spin'][0]
  this_build = 'alpha' unless build[this_build]
  this_spin = 'combo' unless spin[this_spin]

  host = sanitize_host(params['host'][0])
  hash = sanitize_hash(params['hash'][0])

  ks = "ks/#{this_build}-#{this_spin}"
  ks += "/" + host unless host.nil?
  ks += "/" + hash unless hash.nil?
  
  url = "http://buildvm-devops.usersys.redhat.com/" + ks

  puts cgi.header
  puts <<"INFO1"
	<!doctype html>
	<html lang="en"><body><form>
	<h2>Use your kickstart</h2>
	<p>
	Your kickstart is available at this address:
	<br>
	<a href="#{url}">#{url}</a>
	</p><p>
	On our lab machines, kickstart this VM with this command line:
	<br><pre>
# ~/bin/kicknode #{host || 'vm-name'} #{ks}
	</pre>
	The kickstart just installs repos and RPMs 
	- does not run ss-setup scripts
	</p>
INFO1
  puts <<"INFO2" if host
	<p>When the kickstart is complete, you should be able to:
	<pre>
$ ssh root@#{host}.usersys.redhat.com  # password "dog8code"
	</pre></p>
	<p>You may also want to add this for convenience:
	<pre>cat >> ~/.ssh/config &lt;&lt;SSH
Host #{host}
  HostName #{host}.usersys.redhat.com
  User      root
  IdentityFile ~/.ssh/libra.pem
SSH
	</pre> ... which if all goes well, enables you to: <pre>
$ ssh #{host}  # no password
	<pre></p>

INFO2
  puts '</body></html>'

else
  #############################################################
  # print the kickstart

  this_build = build['alpha']
  this_spin = spin['combo']

  # path = /tag(-tag)*/host/hash
  nothing, tags, host, hash = path.split('/')
  # split the tags in the first part of the path
  # run them through the hashes
  tags.split('-').each do |tag|
    this_build = build[tag] || this_build
    this_spin = spin[tag] || this_spin
  end
  repo_name, baseurl = this_build
  
  # then extract host and hash if present
  host = sanitize_host(host)
  hash = sanitize_hash(hash)
  host = hash = nil unless host && hash

  host = host ? <<"HOST" : ""
(
# set up RH internal DDNS so we'll know the hostname!
yum localinstall -y http://hdn.corp.redhat.com/rhel6-csb/RPMS/noarch/redhat-ddns-client-1.3-4.noarch.rpm

echo "#{host} usersys.redhat.com #{hash}" > /etc/redhat-ddns/hosts
redhat-ddns-client enable
redhat-ddns-client update
redhat-ddns-client update

) 2>&1 |tee -ai /root/post_install.log
HOST

  puts cgi.header 'text/plain'
  puts <<"KS"

install
lang en_US.UTF-8
keyboard us
services --enabled=ypbind,ntpd,network,logwatch
network --onboot yes --device eth0
# password=dog8code
rootpw  --iscrypted $6$QgevUVWY7.dTjKz6$jugejKU4YTngbFpfNlqrPsiE4sLJSj/ahcfqK8fE5lO0jxDhvdg59Qjk9Qn3vNPAUTWXOp9mchQDy6EV9.XBW1
firewall --service=ssh
authconfig --enableshadow --passalgo=sha512
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --driveorder=vda --append=" rhgb crashkernel=auto quiet console=ttyS0"

# repositories for install-time only
repo --name=rhel63 --baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/x86_64/os/
repo --name=rhel63-opt --baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/optional/x86_64/os/
repo --name=epel --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=x86_64
repo --name=#{repo_name} --baseurl=#{baseurl}


# The following is the partition information
clearpart --all --initlabel
firstboot --disable
lang en_US
keyboard us
reboot

part /boot --fstype=ext4 --size=500
part pv.253002 --grow --size=1
volgroup vg_vm1 --pesize=4096 pv.253002
logvol / --fstype=ext4 --name=lv_root --vgname=vg_vm1 --grow --size=1024 --maxsize=51200
logvol swap --name=lv_swap --vgname=vg_vm1 --grow --size=2016 --maxsize=4032

%packages
@core
@server-policy
ntp
git
screen
telnet
lsof
# non-base RPMs for this spin (if any):
#{this_spin}

%post

# Set up ntp
(
echo "-- NTP --"
date

# do an initial ntpdate to set the correct time and sync up the hardware clock

/usr/sbin/ntpdate clock.corp.redhat.com
/sbin/hwclock --systohc

# make ntpd check our internal clock server
sed -e '/^server [^0]/ d' -e 's/^server.*/server clock.corp.redhat.com/' -i /etc/ntp.conf 

) 2>&1 |tee -ai /root/post_install.log

# TODO generate an ssh keypair from libra.pem and check it in
mkdir /root/.ssh
chmod 600 /root/ssh
cat >> /root/.ssh/authorized_keys << KEYS
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkMc2jArUbWICi0071HXrt5uofQam11duqo5KEDWUZGtHuMTzuoZ0XEtzpqoRSidya9HjbJ5A4qUJBrvLZ07l0OIjENQ0Kvz83alVGFrEzVVUSZyiy6+yM9Ksaa/XAYUwCibfaFFqS9aVpVdY0qwaKrxX1ycTuYgNAw3WUvkHagdG54/79M8BUkat4uNiot0bKg6VLSI1QzNYV6cMJeOzz7WzHrJhbPrgXNKmgnAwIKQOkbATYB+YmDyHpA4m/O020dWDk9vWFmlxHLZqddCVGAXFyQnXoFTszFP4wTVOu1q2MSjtPexujYjTbBBxraKw9vrkE25YZJHvbZKMsNm2b libra_onprem
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUq7W38xCZ9WGSWCvustaMGMT04tRohw6AKGzI7P7xql5lhCAReyt72n9qWQRZsE1YiCSQuTfXI1oc8NpSM7+lMLwj12G8z3I1YT31JHr9LLYg/XIcExkzfBI920CaS82VqmKOpI9+ARHSJBdIbKRI0f5Y+u4xbc5UzKCJX8jcKGG7nEiw8zm+cvAlfOgssMK+qJppIbVcb2iZNTsw5i2aX6FDMyC+b17DQHzBGpNbhZYxuoERZVRcnYctgIzuo6fD60gniX0fVvrchlOnubB1sRYbloP2r6UE22w/dpLKOFE5i7CA0ZzNBERZ94cIKumIH9MiJs1a6bMe89VOjjNV libra
KEYS
restorecon -R /root/.ssh

# enable internal RHEL repos (main + extras)
# a customer can do this with their bits, or just register their system
cat >> /etc/yum.repos.d/rhel.repo << RHEL
[rhel63]
name=rhel63
baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/x86_64/os/
enabled=1
gpgcheck=0

[rhel63-opt]
name=rhel63-opt
baseurl=http://download.devel.redhat.com/released/RHEL-6/6.3/Server/optional/x86_64/os/
enabled=1
gpgcheck=0

RHEL

# enable repo with our build of crankcase
cat >> /etc/yum.repos.d/openshift_devops.repo << YUM

[#{repo_name}]
name=OpenShift DevOps
baseurl=#{baseurl}
enabled=1
gpgcheck=0

YUM

# enable the EPEL
rpm -ivh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm

#{host}

%end
KS

end
