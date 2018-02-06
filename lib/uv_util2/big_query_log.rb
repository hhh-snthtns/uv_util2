require 'active_support'
require 'active_support/core_ext'
require 'google/cloud/bigquery'
require 'csv'
require 'tempfile'

module UvUtil2
  class BigQueryLog
    # 初期化
    # @param project [Google::Cloud::Bigquery::Project] BigQueryプロジェクト
    # @param dataset_name [String] データセット名
    # @param prefix [String] テーブル名の接頭子
    # @param min_count [Integer] テーブルを分単位で分割する場合の分数
    # @param logger [Logger] ロガー
    # @param expiration [Integer] データセットの有効期限
    #
    def initialize(project, dataset_name, prefix, min_count: nil, logger: nil, expiration: nil)
      @project = project
      @dataset_name = dataset_name
      @prefix = prefix
      @min_count = min_count
      @logger = logger
      @expiration = expiration
    end

    # 時間別テーブル作成
    # @param now [Time] 現在日時
    # @param block [Proc] テーブルにカラムを追加する処理を行うブロック
    #
    def create_table(now: nil, &block)
      # テーブル名の日付部分を決定
      # 翌日1日分のテーブルを作成する
      target_at = (now.nil? ? Time.now : now) + 1.day
      date_str = target_at.strftime('%Y%m%d')

      # データセット取得
      dataset = get_dataset

      if @min_count.nil?
        # 時間別テーブル作成
        (0 .. 23).each do |hour|
          create_hour_min_table(dataset, now: target_at, hour: hour, block: block)
        end
      else
        # 分で分割してテーブル作成
        (0 .. 23).each do |hour|
          (0..59).each_slice(@min_count).map(&:first).each do |min|
            create_hour_min_table(dataset, now: target_at, hour: hour, min: min, block: block)
          end
        end
      end
    end

    # データをテーブルに保存する
    # @param data [Array<Array<String>>] テーブルに登録する二次元配列のデータ
    # @param now [DateTime] ログ出力日時
    # @param block [Proc] ログ保存先テーブルが存在しなかった場合に実行するスキーマ作成処理
    #
    def load_data(data, now: nil, &block)
      # データセットの取得または作成
      dataset = get_dataset

      # テーブルの取得または作成
      bq_table = create_hour_min_table(dataset, now: now, min: calc_min_for_table, block: block)

      # アップロードするCSVファイルを一時ファイルとして作成する
      Tempfile.open(['bq_', '.csv']) do |file|
        # データをCSV形式で一時ファイルに書き込む
        data.each do |row|
          record = CSV.generate_line(row, {force_quotes: true, row_sep: "\r\n"})
          file.write(record)
        end

        # CSVフィルをアップロードする
        file.rewind
        bq_table.load file
      end
    end

    private

    # データセットの取得または作成
    # @return [Google::Cloud::Bigquery::Dataset] データセット
    #
    def get_dataset
      # 取得できたらそのまま返却する
      dataset = @project.dataset(@dataset_name)
      return dataset if !dataset.nil?

      # データセットを新規作成
      begin
        @project.create_dataset(@dataset_name, expiration: @expiration)

      rescue => e
        # データセットがすでに存在する場合は例外を無視
        raise e if !duplicate_dataset?(e)
        alert(e)
        @project.dataset(@dataset_name)
      end
    end

    # 時間単位のテーブル取得または作成
    # @param dataset [Google::Cloud::Bigquery::Dataset] データセット
    # @param now [DateTime] 現在日時
    # @param hour [Integer] テーブル名の時間
    # @param min [Integer] テーブル名の分
    # @param block [Proc] ログ保存先テーブルが存在しなかった場合に実行するスキーマ作成処理
    # @return [Google::Cloud::Bigquery::Table] テーブル
    #
    def create_hour_min_table(dataset, now: nil, hour: nil, min: nil, block: nil)
      target_at = (now.nil? ? Time.now : now)
      date_str = target_at.strftime('%Y%m%d')
      hour_str = sprintf('%02d', hour.nil? ? target_at.hour : hour)
      min_str = sprintf('%02d', min.nil? ? target_at.min : min) if @min_count

      # テーブル名を決定
      table_name = [@prefix, date_str, "#{ hour_str }#{ min_str || '' }"].join('_')

      # テーブルを取得できたらそのまま返却
      bq_table = dataset.table(table_name)
      return bq_table if !bq_table.nil?

      # テーブル作成
      begin
        dataset.create_table(table_name) do |table|
          table.schema do |schema|
            block ? block.call(schema) : default_schema(schema)
          end
        end

      rescue => e
        # テーブルがすでに存在する場合は例外を無視
        raise e if !duplicate_table?(e, table_name)
        alert(e)
        dataset.table(table_name)
      end
    end

    # ログテーブルにカラムを作成する
    # @param schema [Google::Cloud::Bigquery::Schema] スキーマ
    # @note
    #   service_cd - ログ送信を行ったサービスの名称
    #   created_at - ログの送信日時
    #   message_cd - ログの内容、GROUP BYに指定できる内容がよい
    #   log_json - ログの詳細、JSON形式で保存する
    #
    def default_schema(schema)
      schema.string 'service_cd', mode: :required
      schema.timestamp 'created_at', mode: :required
      schema.string 'message_cd', mode: :required
      schema.string 'log_json', mode: :required
    end

    # データセットがすでに存在する例外かどうかを判定
    # @param e [Exception] 例外
    # @return [Boolean] データセットがすでに存在する例外の場合にtrue
    #
    def duplicate_dataset?(e)
      /duplicate: Already Exists: Dataset #{@project.project}:#{@dataset_name}/
    end

    # テーブルがすでに存在する例外かどうかを判定
    # @param e [Exception] 例外
    # @param table_name [String] テーブル名
    # @return [Boolean] テーブルがすでに存在する例外の場合にtrue
    #
    def duplicate_table?(e, table_name)
      table_cd = "#{@project.project}:#{@dataset_name}.#{table_name}"
      /duplicate: Already Exists: Table #{table_cd}/.match?(e.message)
    end

    # ログ出力
    # @param e [Exception] 例外
    # @param level [Symbol] ログレベル
    #
    def alert(e, level: :info)
      return if @logger.nil?
      @logger.public_send(level, e.message)
    end

    # 現在日時からテーブル名の分数を計算. 分単位のテーブル分割をしていない場合 nil を返す
    # @param now [Time] 現在日時
    #
    def calc_min_for_table(now: Time.now)
      return nil if now.nil? || @min_count.nil?
      (now.min.to_f / @min_count.to_f).floor * @min_count
    end
  end
end
