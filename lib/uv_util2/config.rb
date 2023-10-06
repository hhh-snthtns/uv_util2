require "yaml"
require "erb"
require 'active_support'
require 'active_support/core_ext'

module UvUtil2
  class Config
    def self.read(path, env=nil)
      open(path) do |f|
        yaml = nil
        begin
          yaml = ::YAML::load(::ERB.new(f.read).result, aliases: true).deep_symbolize_keys
        rescue ArgumentError
          yaml = ::YAML::load(::ERB.new(f.read).result).deep_symbolize_keys
        end
        env.present? ? yaml[env] : yaml
      end
    end
  end
end

