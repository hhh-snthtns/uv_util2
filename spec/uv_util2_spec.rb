require 'spec_helper'
describe UvUtil2 do
  it 'config' do
    res = UvUtil2::Config.read(YAML_FILE, :development)
    expect(res[:api][:url]).to eq("http://localhost:9393/")
  end

  it 'db' do
    config = UvUtil2::Config.read(YAML_FILE, :development)
    db = UvUtil2::Db.make_db(config[:db_connect])
    open(STORED_PROCEDURE_FILE) do |f|
      db.run f.read
    end
    begin
      db["select test_error()"].all
      violated "allwaiys fail!"
    rescue Sequel::DatabaseError => e
      p e.message
      expect(e.db_code).to eq("U0001")
    end
  end
end
