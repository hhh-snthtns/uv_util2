require 'spec_helper'
describe UvUtil2 do
  it 'config' do
    res = UvUtil2::Config.read(YAML_FILE, :development)
    expect(res[:api][:url]).to eq("http://localhost:9393/")
  end
end
