require "yaml"
require "erb"
require 'active_support'
require 'active_support/core_ext'

module UvUtil2
  class Config
    def self.read(path, env=nil)
      open(path) do |f|
        yaml = parse(::ERB.new(f.read).result)
        env.present? ? yaml[env] : yaml
      end
    end

    def self.parse(file_object)
      begin
        # for Ruby 3.x+
        ::YAML::load(::ERB.new(f.read).result, aliases: true).deep_symbolize_keys
      rescue ArgumentError
        ::YAML::load(::ERB.new(f.read).result).deep_symbolize_keys
      end
    end
    private_class_method :parse
  end
end

