#!/bin/bash -x
# $1 - action
# $2 - OSE version (1.2.z, 2.0)
# $3 - puddle URL

function build_image()
{
  # step 1: create an VM (retry until success)
  vm_ip=${IP:-10.0.0.1}  #cheat for now

  # step 2: copy everything to it
  scp -oBatchMode=yes * root@${vm_ip}: || bail "Couldn't copy to host: $!"

  # step 3: run build there
  for i in 1 2 3 4; do
    ssh -oBatchMode=yes root@${vm_ip} "./puddle-image.sh install $1 $2" |& grep "OpenShift: Completed installing RPMs."
    [ $? = 0 ] && break   # succeeded if we saw that line
    echo "Install failed"
    echo "$!"
    echo "waiting to try again"
    sleep 60
  done

  # step 4: wait for reboot to complete, then cleanup.
  for i in $(seq 1 20); do
    echo "waiting for VM to reboot"
    sleep 20
    ssh -oBatchMode=yes root@${vm_ip} "./puddle-image.sh cleanup"
    [ $? = 0 ] && break
  done

  # step 5: snapshot VM
  # step 6: terminate the VM
  # step 7: proclaim success
  echo "Created image for puddle $2"
}

function install_openshift()
{
# $1 - OSE version (1.2.z, 2.0)
# $2 - puddle URL
  # step 1: pull down the right openshift.sh
  for i in $(seq 1 10); do
    curl -s "https://raw.github.com/openshift/openshift-extras/enterprise-${1}/enterprise/install-scripts/generic/openshift.sh" -o openshift.sh && break
    rm -f openshift.sh
    sleep 5
  done
  # not as concerned about this failing; just a convenience
  curl -s https://install.openshift.com/portable/oo-install-ose.zip -o oo-install-2.0.zip

  # step 2: set the right parameters
  #export CONF_INSTALL_METHOD=rhsm
  #export CONF_RHN_USER=qa@redhat.com
  #export CONF_RHN_PASS=AeGh8phugee5
  #export CONF_SM_REG_POOL=8a85f9863cf496b3013da2315a27694d
  #or:
  export CONF_INSTALL_METHOD=yum
  export CONF_CDN_REPO_BASE=http://cdn.rcm-qa.redhat.com/content/dist/rhel/server/6/6Server/x86_64

  export CONF_ACTIONS=validate_preflight,configure_repos,install_rpms,reboot_after
  export CONF_ROUTING_PLUGIN=true # so the RPM is installed anyway
  export CONF_OSE_EXTRA_REPO_BASE=$2  # pulls in the puddle

  # step 3: run the script and report results
  chmod +x openshift.sh
  ./openshift.sh |& tee -a openshift.log \
	  | stdbuf -oL -eL grep -i '^OpenShift:' # filter to the status lines
}

function cleanup_vm()
{
  # whatever we need to do to make the VM snapshot-able
  subscription-manager unregister
  rm -f /etc/udev/rules.d/70-persistent-net.rules
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  mv id_rsa /root/.ssh
  cat id_rsa.pub >> /root/.ssh/authorized_keys
  rm -f id_rsa.pub
}

function bail()
{
  echo $1
  exit 1
}

case $1 in
	build  )
		build_image "$2" "$3"
		;;
	install )
		install_openshift "$2" "$3"
		;;
	cleanup )
                cleanup_vm
		;;
	* )
		echo "Format is: $0 <build|install|cleanup> <1.2.z|2.0> <puddle URL>"
		exit 1
		;;
esac
