module OSEUpgrader
  # this is to be extended into modules for finding the release-specific upgrader
  module Finder
    class Error < StandardError; end

    # ensure the upgrader for this number is available and loaded
    # Upgraders must have class name OSEUpgrade::<Target>::Number<num>
    # and must live in <target>/upgrades/<num>/ with upgrader.rb as the entry point
    def find_upgrader(params = {})
      upgrader = "Number#{params[:number]}"
      if self.const_defined? upgrader  #self = e.g. OSEUpgrader::Broker
        return self.const_get(upgrader).new(params)
      elsif File.exists?(u = "#{File.dirname(__FILE__)}/#{self.upgrade_target}/upgrades/#{params[:number]}/upgrader.rb")
        begin
          load u
          return self.const_get(upgrader).new(params)
        rescue LoadError => e
          raise Error.new("File #{u} failed to load")
        rescue NameError => e
          raise Error.new("File #{u} did not define class #{self.to_s}::#{upgrader}")
        end
      end
      return nil
    end
  end # Finder module
end
