module Visage
  class Upgrade
    class V3
      class << self
        def version
          3
        end

        def run
          root = Pathname.new(Profile.config_path)
          profiles_dot_yaml = root.join('profiles.yaml')
          data = YAML.load(profiles_dot_yaml.read)

          data.each_pair do |url, attrs|
            graphs = []

            @plugins = {}
            attrs[:metrics].each do |m|
              plugin, instance = m.split('/')
              @plugins[plugin] ||= []
              @plugins[plugin] << instance
            end

            plugins = @plugins.map {|plugin, instances| "#{plugin}/#{instances.join(',')}"}
            plugins = @plugins.map {|plugin, instances| "#{plugin}"}

            attrs[:hosts].each do |host|
              plugins.each do |plugin|
                graphs << {
                  :host        => host,
                  :plugin      => plugin,
                  :percentiles => attrs[:percentiles],
                }
              end
            end

            attributes = {
              :anonymous => false,
              :name      => attrs[:profile_name],
              :graphs    => graphs,
            }

            profile = Profile.new(attributes)
            if not profile.save
              puts "Could not upgrade profile #{profile.id}."
              puts "These were the error messages:"
              profile.errors.messages.each do |msg|
                puts " - #{msg.join(' ')}"
              end
              puts "Exiting!"
              exit 128
            end
          end

          # Move profiles.yaml out of the way
          backup = profiles_dot_yaml.dirname.join("profiles.yaml.#{Time.now.to_i.to_s}")
          profiles_dot_yaml.rename(backup)
        end
      end
    end
  end
end

