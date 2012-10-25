Amazon Installation
==================

Background
----------

For this CloudFormation template to work, we are using init.d scripts
that will run a script embedded in the UserData for the image.  The
image build process is as follows:

    # Download the user data run scripts
    # Based on the following thread - https://forums.aws.amazon.com/thread.jspa?threadID=87599
    cd /etc/init.d/
    wget https://forums.aws.amazon.com/servlet/JiveServlet/download/92-87599-322826-6150/ec2-ssh-host-key-gen
    wget https://forums.aws.amazon.com/servlet/JiveServlet/download/92-87599-322826-6169/ec2-run-user-data
    chmod 755 ec2-*

    # Start those services on boot
    chkconfig ec2-ssh-host-key-gen on
    chkconfig ec2-run-user-data on

    # Install some base packages
    yum install -y gcc ruby ruby-devel python python-devel

    # Update the remainder of the packages
    yum update -y

The resulting image is saved as the AMI:

    rhel6.3-openshift-cloud-init

Running
-------

1. Upload the OpenShift.template as your CloudFormation Stack
2. Watch it run...

Updating from the source kickstart
----------------------------------

The general updating process for refreshing the openshift-amz.sh script
is as follows.

*Note:* This is automated in the build.sh file

1. Download the latest kickstart into the root directory as
   'openshift.ks'

    wget https://raw.github.com/gist/3901379/openshift.ks

2. Run the build script

    cd amazon
    ./build.sh
