# OpenShift Enterprise Upgrade Developers' Guide #

The OpenShift Enterprise upgrade tool is based in large part on the release
procedures of OpenShift Online.  Although Enterprise and Online are both based
on OpenShift Origin and therefore can share much of the same procedures for
upgrading, Online follows a 3-week release cycle (i.e., there is usually a new
release every 3 weeks) whereas the release cycle of Enterprise is longer.  For
this reason, a given release of Enterprise encompasses many releases of Online,
and some effort is involved in compiling the upgrade procedures of multiple
Online releases, as well as hotfixes between releases, into the upgrade
procedure for one release of Enterprise.

Each Online release or hotfix is documented by a release ticket; see
<https://engineering.redhat.com/trac/Libra/wiki/Releases> for a list of past
release tickets.  Each ticket provides a general outline of the release,
timeline, major changes, caveats, upgrade steps, etc.

### `rhc-admin-migrate-datastore` and `oo-admin-upgrade` ###

For Online, the bulk of each upgrade is handled by two tools: `oo-admin-upgrade`
and `rhc-admin-migrate-datastore`. `oo-admin-upgrade` updates files inside of
gears while `rhc-admin-migrate-datastore` updates data in MongoDB.

`oo-admin-upgrade` and `rhc-admin-migrate-datastore` are both executed on
a broker host.  Because gears reside on node hosts, `oo-admin-upgrade` must
direct nodes remotely on what steps to take.  Concretely, `oo-admin-upgrade`
invokes the upgrade action of the OpenShift MCollective agent running on node
hosts.  This upgrade action in turn invokes methods of the
OpenShift::GearUpgradeExtension module, which must be configured in
`/etc/openshift/node.conf`, and then executes the `upgrade` script of each
instantiated cartridge within each gear.  `oo-admin-upgrade` and
GearUpgradeExtension are updated with each Online release and do exactly the
steps that are required to upgrade to that release from the previous release.

`rhc-admin-migrate-datastore` loads the Rails environment of the OpenShift
Broker in order to perform any necessary manipulations to the data in MongoDB.
In a given release, `rhc-admin-migrate-datastore` operates in multiple stages,
where each stage is performed by a separate invocation of
`rhc-admin-migrate-datastore.` Some stages can be performed with the broker
running (to minimise downtime), some must be run (and all can be run) with the
broker stopped.  Same as `oo-admin-upgrade`, `rhc-admin-migrate-datastore` is
updated with each Online release to do exactly the manipulations that are
required for the particular release.

These tools (`oo-admin-upgrade`, GearUpgradeExtension, and
`rhc-admin-migrate-datastore`) are all written in Ruby.

Typically, to create the upgrade scripts for a single Enterprise release, one
compiles the `rhc-admin-migrate-datastore` scripts for the corresponding
Online releases into a single migration script for Enterprise, and similarly for
`oo-admin-upgrade` and GearUpgradeExtension.

Caveat: Ideally, `rhc-admin-migrate-datastore` would not depend on model
classes, which may behave differently between releases.  In reality, it often
does use model classes to read and write to MongoDB.  Because the code for these
model classes will be updated all at once when the RPMs that ship the code are
updated, Enterprise upgrades thus must be written with this caveat in mind.

Historical note: In the past, each Online release had a separate
`migrate-mongo-2.0.x` script, and the upgrade from RHOSE 1.1 to RHOSE 1.2 uses
these scripts.  In more recent Online releases, these `migrate-mongo-2.0.x`
scripts have been superseded by `rhc-admin-migrate-datastore`.  A given
`migrate-mongo-2.0.x` script was run only once per upgrade whereas
`rhc-admin-migrate-datastore` introduces the multiple stages, and thus it is
preferable to combine the `rhc-admin-migrate-datastore` scripts from multiple
Online releases into one script for the corresponding Enterprise release where
that script combines the contents of `rhc-admin-migrate-datastore` grouped by
stage.

Historical note: Upgrade steps related to gears and cartridges used to be manual
steps within release tickets, as can be seen in the upgrade from RHOSE 1.1 to
RHOSE 1.2. `oo-admin-upgrade` was introduced in later Online releases to provide
a more unified and automated upgrade process for gears.

Note: Some Online releases do not have gear or data migrations.  When writing an
Enterprise upgrade, check the version listed at the beginning of
`rhc-admin-migrate-datastore` or `oo-admin-upgrade` in each relevant Online
release, and only incorporate each script from that Online release into the
Enterprise upgrade if the script from Online identifies that release version.

### Other Steps ###

Any upgrade steps that are not handled by `rhc-admin-migrate-datastore` or
`oo-admin-upgrade` should be outlined in the Online release tickets.
Note that the Online release tickets include much information that is not
relevant to Enterprise (e.g., changes to `site/` or to `build/devenv/`).

Furthermore, there may be additional changes to configuration files that are not
documented in the release tickets.  Check the Git history for the installation
scripts in the openshift-extras repository and to important configuration files
in the origin-server repository for items that may not be in release tickets.

### Bootstrapping the upgrade process ###
One interesting part of the upgrade is when the process switches from one
version of the codebase to the other.  Take the 2.0->2.1 upgrade for example.
Part of the upgrade starts on the 2.0 codebase then swithes to the 2.1
codebase.  Thus far this has always happened in the `begin` step.

For the 2.0->2.1 upgrade the `begin` step actually runs in the 2.0 version of
the ose-upgrade tool.  The most important step it run is to configure the
machine to the 2.1 channels and install the 2.1 version of ose-upgrade.

Another interesting bootstrapping step is handled by
`/etc/openshift/upgrade/state.yaml`.  As the name suggests that where the state
of the state machine is kept.  If a machine is freshly installed with 2.1 it
will have a state.yaml that looks like this:

    --- 
    steps: 
      host: 
        begin: 
          status: NONE
    status: COMPLETE
    number: 3

That is handled in the installation of `openshift-enterprise-release`.  If RPM
detects that no `state.yml` exists it assumes that it's a new installation and
markes the corresponding upgrade complete by running the following command in
the RPM %post:

    ose-upgrade --complete %{upgrade_number} >& /dev/null  

The number is set in the spec file and corresponds to the mapping stored in
main.rb:

    VERSION_MAP = {
        0  => "1.1",
        1  => "1.2",
        2  => "2.0",
        3  => "2.1",
    }

This is why it's absolutely critical for the version of
`openshift-enterprise-release` to match the version that is actually installed.
If somehow someone installed OSE 2.0 without installing the 2.0 version of
`openshift-enterprise-release` they would have no state file.  If they then
managed to install the 2.1 version of the package the state file would record
that the 2.1 upgrade was already complete.  To fix that they would have to
manually edit the state file.  Thankfully, the way channels are configured in
OSE should not allow this to happen.  However, more and more customers will
likely begin sync'ing the content from RHN and in doing so expose themselves to
this sort of error.

Taking a look at a machine that failed to upgrade 2.0 to 2.1.  We can see the
state.yam looks quite different:

    ---
    steps:
      broker:
        outage:
          previous_status: UPGRADING
          status: COMPLETE
        pre:
          previous_status: UPGRADING
          status: COMPLETE
        rpms:
          status: NONE
      node:
        outage:
          previous_status: UPGRADING
          status: COMPLETE
        pre:
          previous_status: UPGRADING
          status: COMPLETE
        rpms:
          previous_status: UPGRADING
          status: FAILED
      host:
        begin:
          previous_status: UPGRADING
          status: COMPLETE
    run_scripts:
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/node/upgrades/3/outage/03-node-shutdown-services: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/pre/04-broker-migrate-datastore-prerelease: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/host/upgrades/3/repo/01-new-repos: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/pre/02-broker-clear-most-pending-ops: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/step_lock oseupgrade_3_pre: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/node/upgrades/3/rpms/04-both-yum-update: FAILED
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/node/upgrades/3/pre/02-node-backup-conf-files: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/step_lock oseupgrade_3_pre done: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/pre/02-broker-backup-conf-files: COMPLETE
      /usr/lib/ruby/site_ruby/1.8/ose-upgrade/broker/upgrades/3/outage/03-broker-shutdown-services: COMPLETE
    number: 3
    status: STARTED

### Structure of `ose-upgrade` ###
`ose-upgrade` implements a state machine.  The executable is
`./upgrades/bin/ose-upgrade`.  Aside from parsing options the most important
thing is does is call `lib/ose-upgrade/main.rb` which in turn calls
`lib/ose-upgrade.rb`.  Those files implement the majored of the state machine
framework.

From there the main thing to know is that we can implement classes for each
type of upgrade.  For example the `Broker` class tells the framework how to
load the scripts under `lib/ose-upgrade/broker/upgrades/`.  The frame then
looks for the `upgrade.rb` script that corresponds to the upgrade version (3 in
the example above).  The `upgrade.rb` script tells the framework about the
steps that are needed.  Those steps correspond to directories under
`lib/ose-upgrade/broker/upgrades/$version`.  Inside those directories are
scripts that will be called by the framework.  The nice thing is that this
allows the scripts to be written in virtually any language.  The scripts
themselves are executed in lexical order.

The state machine keeps track of exit status of each script.  The scripts
themselves must be reentrant.
