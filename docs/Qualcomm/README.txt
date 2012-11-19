== Steps ==
* Install EPEL
* Enable the 'Optional' RHEL 6 Server repos
* Sync content from ftp://partners.redhat.com/276b67e8dba70770fc4d0746f0e5003c/AUG-09-2012/
* I would highly recommend simply installing the broker and node on 1 machine
  for now.  Once we have that working we can setup a multi-node environment.
  On your server run:

  $ yum install -y openshift-origin-broker openshift-origin-node cartridge-* lsof
  $ ss-setup-broker --static-dns $IPs_from_/etc/resolv.conf (comma seperated)

* On all machines where you want to run 'rhc' edit /etc/openshift/express.conf
  and set libra_server appropriately.  If you just want to run rhc from the
  broker you can set it to localhost.  It's also nice to set:

  default_rhlogin = 'admin'

A few good things to note:

* The default admin password is 'admin' as well.  To create a nodejs app you can run:

  # rhc domain create -n mydomain -l admin -p admin
  # rhc app create -a mynodejsapp1 -t nodejs-0.6 -p admin -l admin

* It's really important the broker and nodes have static IPs in a production
  environment.  If you are only testing things out then it's only necessary for
  the IPs to be mostly static.
* I have been adding my broker IP to my /etc/resolv.conf so that I can
  reach the example.com apps.  This is a workaround until we have better DNS
  integration.  If you have any ideas here we would love to hear them. :)
