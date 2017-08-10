require './spec/spec_helper'
require 'uv_util2/big_query_log'

RSpec.describe UvUtil2::BigQueryLog do

  before(:all) do
#    @logger = Logger.new(STDOUT)
    @logger = nil
    @project_name = 'test'
    @dataset_name = 'ccc'
  end

  # BigQueryプロジェクトをモック
  let (:mock_bq_project) do
    mock_schema = double('schema')
    allow(mock_schema).to receive(:string) { |name| }
    allow(mock_schema).to receive(:timestamp) { |name| }

    mock_table = double('table')
    allow(mock_table).to receive(:schema) do |schema, &block|
      block.call(mock_schema)
    end

    allow(mock_table).to receive(:load) do |file|
    end

    mock_dataset = double('dataset')
    allow(mock_dataset).to receive(:create_table) do |table_id, &block|
      if /^duplicate_.+/.match?(table_id)
        raise "duplicate: Already Exists: Table #{@project_name}:#{@dataset_name}.#{table_id}"
      end
      block.call(mock_table)
    end

    allow(mock_dataset).to receive(:table) do |table_id|
      mock_table
    end

    mock_project = double('project')
    allow(mock_project).to receive(:dataset) do |dataset_id|
      'nothing' == dataset_id ? nil : mock_dataset
    end

    allow(mock_project).to receive(:project) do
      @project_name
    end

    allow(Google::Cloud::Bigquery).to receive(:new) do |project, keyfile|
      mock_project
    end
  end

  # BigQueryプロジェクトを生成
  let (:get_bq_project) do
    mock_bq_project
    project = Google::Cloud::Bigquery.new(
      project: @project_name,
      keyfile: 'bbb'
    )
  end

  describe '準正常系' do
    describe 'テーブル作成' do
      it '存在しないデータセット名を指定すると例外になること' do
        dataset_name = 'nothing'
        bq_log = UvUtil2::BigQueryLog.new(get_bq_project,
          dataset_name,
          logger: @logger)

        expect {
          bq_log.create_table('ddd')
        }.to raise_error("not found the dataset #{dataset_name}")
      end
    end
  end

  describe '正常系' do
    # BigQueryLogオブジェクトを生成
    let (:get_bq_log) do
      UvUtil2::BigQueryLog.new(get_bq_project, @dataset_name, logger: @logger)
    end

    describe 'テーブル作成' do
      it 'デフォルトのスキーマでテーブルの作成に成功すること' do
        get_bq_log.create_table('ddd')
      end

      it 'スキーマ指定でテーブルの作成に成功すること' do
        get_bq_log.create_table('ddd') do |schema|
          schema.string 'service_cd', mode: :required
          schema.timestamp 'created_at', mode: :required
        end
      end

      it 'すでに存在するテーブル名を指定した場合成功すること' do
        get_bq_log.create_table('duplicate')
      end
    end

    describe 'データ読み込み' do
      it 'データの読み込みに成功すること' do
        data = [['1a', '1b', '1c', '1d'], ['2a', '2b', '2c', '2d']]
        get_bq_log.load_data('ddd', data)
      end
    end
  end

end
