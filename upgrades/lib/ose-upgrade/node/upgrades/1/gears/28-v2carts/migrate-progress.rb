module OpenShiftMigration
  class MigrationProgress
    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
      @buffer = []
    end

    def incomplete?(marker)
      not complete?(marker)
    end

    def complete?(marker)
      File.exists?(marker_path(marker))
    end

    def mark_complete(marker)
      IO.write(marker_path(marker), '')
      log "Marking step #{marker} complete"
    end

    def done
      Dir.glob(File.join('/var/lib/openshift', @uuid, 'app-root', 'data', '.migration_complete*')).each do |entry|
        FileUtils.rm_rf(entry)
      end
    end

    def marker_path(marker)
      File.join('/var/lib/openshift', @uuid, 'app-root', 'data', ".migration_complete_#{marker}")
    end

    def log(string)
      @buffer << string
      string
    end

    def report
      @buffer.join("\n")
    end
  end
end