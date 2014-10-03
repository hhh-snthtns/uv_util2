# coding: utf-8

require 'bundler/setup'
require 'uv_util2/config'
require 'uv_util2/db'

YAML_FILE = File.dirname(__FILE__) + "/config.yaml"
STORED_PROCEDURE_FILE = File.dirname(__FILE__) + "/stored_procedue.sql"

RSpec.configure do |config|
  # some (optional) config here
end
