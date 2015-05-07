require "yaml"
require "erb"
require 'active_support'
require 'active_support/core_ext'

module UvUtil2
  class Config
    def self.read(path, env=nil)
      open(path) do |f|
        yaml = ::YAML::load(::ERB.new(f.read).result).deep_symbolize_keys
        env.present? ? yaml[env] : yaml
      end
    end
  end
end

