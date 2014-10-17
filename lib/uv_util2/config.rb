require "yaml"
require "erb"
require 'active_support'
require 'active_support/core_ext'

module UvUtil2
  class Config
    def self.read(path, env)
      open(path) do |f|
        yaml = ::YAML::load(::ERB.new(f.read).result).deep_symbolize_keys
        yaml[env]
      end
    end
  end
end

