# Handle upgrading various persistent data when upgrading.
#
# Currently used for upgrading the profile data.
module Visage
  class Upgrade
    class << self
      def run
        # Build a list of upgrades that can be run
        upgrades      = []
        upgrade_files = Dir.glob(File.join(File.dirname(__FILE__), 'upgrade', '*'))
        upgrade_files.each do |f|
          require(f)
          upgrades << Visage::Upgrade::const_get(File.basename(f).split('.').first.upcase)
        end

        # Skip upgrades that have been run
        to_run = upgrades.reject {|u| u.version <= version}
        # Run the remaining upgrades
        to_run.each {|u| u.run}
      end

      # Determine the current profile storage format version
      def version
        config_path       = Pathname.new(Profile.config_path)
        profiles_dot_yaml = config_path.join('profiles.yaml')

        if profiles_dot_yaml.exist?
          data = YAML.load(profiles_dot_yaml.read)
          if data.find_all {|profile, attrs| attrs.key?(:percentiles)}.empty?
            1
          else
            2
          end
        else
          3
        end
      end
    end
  end
end
