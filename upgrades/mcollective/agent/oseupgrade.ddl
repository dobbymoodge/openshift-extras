
metadata    :name        => "OpenShift Enterprise Upgrade Agent",
            :description => "Agent to assist with the ose-upgrade process",
            :author      => "Red Hat, Inc.",
            :license     => "ASL 2.0",
            :version     => "0.2",
            :url         => "http://openshift.redhat.com/",
            :timeout     => 240

action "migrate", :description => "Migrate a gear from previous to current migration number" do
    input :uuid,
          :prompt      => "Gear UUID",
          :description => "Gear UUID to migrate",
          :type        => :string,
          :validation  => '^[a-zA-Z0-9]+$',
          :optional    => false,
          :maxlength   => 40

    input :gear_name,
          :prompt      => "Gear name",
          :description => "Name for gear (first part of hostname before hyphen)",
          :type        => :string,
          :validation  => '^[a-zA-Z0-9]+$',
          :optional    => false,
          :maxlength   => 40

    input :namespace,
          :prompt      => "Cloud user's domain / namespace",
          :description => "Cloud user's domain / namespace",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength   => 40

    input :number,
          :prompt      => "Migration number",
          :description => "Number of migration to run",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength   => 40

    output :output,
           :description => "Output of the migration command",
           :display_as  => "output"

    output :exitcode,
           :description => "Exit code from the migration command",
           :display_as  => "exitcode"
end

action "gear_upgrades_complete", :description => "Mark Gear Upgrades Complete" do
     output :exitcode,
           :description => "Exit code from the gear_upgrades_complete command",
           :display_as  => "exitcode"
end

action "ping", :description => "Check that this agent is present" do
    output :exitcode,
           :description => "Exit code from the ping command",
           :display_as  => "exitcode"
    output :version,
           :description => "Upgrade version",
           :display_as  => "version"
end
