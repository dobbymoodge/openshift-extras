= Setup =
* Install EPEL
* Enable the 'Optional' RHEL 6 Server repos
* wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
  rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
* Use the openshift_onpremise.repo in this dir
* On the broker

    yum install -y openshift-origin-broker openshift-origin-node cartridge-* lsof
    ss-setup-broker --static-dns $IPs_from_/etc/resolv.conf (comma seperated)
    ss-register-dns --with-node-hostname node0 --with-node-ip xx.xx.xx.xx

* On the nodes:
    yum install -y openshift-origin-node cartridge-* lsof
    ss-setup-node --with-broker-ip xx.xx.xx.xx --with-node-hostname node0

* On all machines where you want to run 'rhc'
    mkdir -p ~/.openshift/
    echo 'libra_server=localhost' >> ~/.openshift/express.conf
    echo 'default_rhlogin=admin' >> ~/.openshift/express.conf

Note: I have been adding my broker IP to my /etc/resolv.conf so that I can
reach the example.com apps.  This is a workaround until we have better DNS
integration.  If you have any ideas here we would love to hear them. :)

= Try it out! =
== For all cartridges ==
rhc domain create -ladmin -padmin -n mydomain

# Note that command will create an ssh keypair if it doesn't find one.

== JBoss & Jenkins ==
Here's how to get up and running using the rhc tool:
rhc app create -a myjbossapp1 -t jbossas-7 -p admin
rhc app create -a jenkins -t jenkins-1.4 -p admin
rhc-ctl-app -a myjbossapp1 -e add-jenkins-client-1.4 -p admin

If you would like to see everything done from a fancy GUI you have two options:
  [regular eclipse]
    * Download eclipse from http://www.eclipse.org/downloads/packages/eclipse-ide-java-developers/indigosr2
    * Install the JBoss Tools plugin
        https://openshift.redhat.com/community/faq/how-do-i-install-the-jboss-openshift-tools-plugin-for-eclipse
    * Set libra_server in eclipse.ini according to
        https://openshift.redhat.com/community/wiki/connect-to-openshift-origin-installation-with-jboss-tools
  [JBoss Developer Studio 5GA]
    * Download and install from RH Customer Portal - comes with OpenShift plugins
    * Set libra_server in jbdevstudio.ini according to
        https://openshift.redhat.com/community/wiki/connect-to-openshift-origin-installation-with-jboss-tools
        OR copy jbdevstudio.ini file, edit with -Dlibra_server=$SERVERIP, and use --launcher.ini your_file.ini 
          from the command line
        OR specify -vmargs -Dlibra_server=$SERVERIP from the command line
        
  * Read/watch https://community.jboss.org/en/tools/blog/2012/06/27/deploy-from-eclipse-to-openshift-in-a-breeze
One thing to note is that the rhc tool will create a set of ssh keys if it
doesn't find any available.  The eclipse tools will not.  What I've been doing
is copying the ssh keys that rhc creates locally on my broker over to my laptop
so that I can test eclipse there.  
  * Copy the ssh key to an innocuous location, start eclipse, and add the key 
  location to General/Network Connections/SSH2/Private Keys:  
  (Example: id_dsa,id_rsa,/tmp/id_rsa)
