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

if [ $# -lt 1 -o $# -gt 2 ]; then
	echo "Usage: $0 source_dir [destination_dir]"
	echo "        If destination_dir is not specified, then it will be"
	echo "        the same as source_dir."
	exit 1
fi

if [ $# -eq 2 ]; then
	ROOT_SRC=$1
	ROOT_DST=$2
else
	ROOT_SRC=$1
	ROOT_DST=$1
fi

if [ -d /var/www/html/puddle/build/OpenShiftEnterprise/Beta/$ROOT_SRC ]; then
	cd /var/www/html/puddle/build/OpenShiftEnterprise/Beta/$ROOT_SRC
else
	echo "/var/www/html/puddle/build/OpenShiftEnterprise/Beta/$ROOT_SRC does not exist.  Exiting..."
	exit 1
fi

# Create the destination dir on mirror1

ssh mirror1.ops.rhcloud.com "mkdir -p /srv/pub//origin-server/nightly/enterprise/$ROOT_DST"

# Rsync the files to mirror1

rsync -av -e ssh Infrastructure Node Client JBoss_EAP6_Cartridge root@mirror1.ops.rhcloud.com:/srv/pub/origin-server/nightly/enterprise/$ROOT_DST/

# Rebuild the yum repos

for PACK_SET in Infrastructure Node Client JBoss_EAP6_Cartridge; 
	do ssh mirror1.ops.rhcloud.com "cd /srv/pub/origin-server/nightly/enterprise/${ROOT_DST}/${PACK_SET}/x86_64/os/Packages/; /usr/bin/createrepo -d ." 
done
