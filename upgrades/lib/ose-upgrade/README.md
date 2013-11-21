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

### Structure of `ose-upgrade` ###
