#!/bin/bash
#
#   Copyright 2012 Red Hat Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Owner: Dan Yocum <yocum@redhat.com>
# Creation Date: 2012-10-22
# Purpose:  A utility to push OpenShift Enterprise nightly build to the 
# 	    public mirrors.

if [ $# -ne 1 ]; then
	echo "You need to specify the date, for example: $0 2012-10-22"
	exit 1
fi

DATE=$1

if [ -d /var/www/html/puddle/build/OpenShiftEnterprise/Beta/$1 ]; then
	cd /var/www/html/puddle/build/OpenShiftEnterprise/Beta/$1
else
	echo "/var/www/html/puddle/build/OpenShiftEnterprise/Beta/$1 does not exist.  Exiting..."
	exit 1
fi

ssh mirror1.ops.rhcloud.com "mkdir -p /srv/pub//origin-server/nightly/enterprise/$1"

rsync -av -e ssh Infrastructure Node Client JBoss_EAP6_Cartridge root@mirror1.ops.rhcloud.com:/srv/pub/origin-server/nightly/enterprise/$1/

ssh mirror1.ops.rhcloud.com "for PACK_SET in Infrastructure Node Client JBoss_EAP6_Cartridge; do PATH=/srv/pub/origin-server/nightly/enterprise/$1/$PACK_SET/x86_64/os/Packages/; cd $PATH; createrepo -d .; done"
