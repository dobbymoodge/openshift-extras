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
      FileUtils.touch(marker_path(marker))
      log "Marking step #{marker} complete"
    end

    def has_instruction?(instruction)
      File.exists?(instruction_path(instruction))
    end

    def set_instruction(instruction)
      FileUtils.touch(instruction_path(instruction))
      log "Creating migration instruction #{instruction}"
    end

    def done
      globs = %w(.migration_complete* .migration_instruction*)

      globs.each do |glob|
        Dir.glob(File.join('/var/lib/openshift', @uuid, 'app-root', 'data', glob)).each do |entry|
          FileUtils.rm_rf(entry)
        end
      end
    end

    def marker_path(marker)
      File.join('/var/lib/openshift', @uuid, 'app-root', 'data', ".migration_complete_#{marker}")
    end

    def instruction_path(instruction)
      File.join('/var/lib/openshift', @uuid, 'app-root', 'data', ".migration_instruction_#{instruction}")
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
