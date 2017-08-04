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
    # @param logger [Logger] ロガー
    #
    def initialize(project, dataset_name, logger: nil)
      @project = project
      @dataset_name = dataset_name
      @logger = logger
    end

    # 時間別テーブル作成
    # @param prefix [String] テーブル名プレフィックス
    # @param now [Time] 現在日時
    # @param block [Proc] テーブルにカラムを追加する処理を行うブロック
    #
    def create_table(prefix, now: nil, &block)
      # テーブル名の日付部分を決定
      # 翌日1日分のテーブルを作成する
      target_at = (now.nil? ? Time.now : now) + 1.day
      date_str = target_at.strftime('%Y%m%d')

      # データセット取得
      dataset = get_dataset
      raise "not found the dataset #{@dataset_name}" if dataset.nil?

      # 時間別テーブル作成
      (0 .. 23).each do |hour|
        table_name = "#{prefix}_#{date_str}_#{hour}"

        begin
          # テーブル作成
          dataset.create_table(table_name) do |table|
            table.schema do |schema|
              block ? block.call(schema) : default_schema(schema)
            end
          end

        rescue => e
          # テーブルがすでに存在する場合はエラーを無視して次へ進む
          raise e if !duplicate_table?(e, table_name)
          alert(e)
        end
      end
    end

    # テーブル取得
    # @param table_id [String] テーブル名
    # @return [Google::Cloud::Bigquery::Table] テーブル
    #
    def table(table_id)
      get_dataset.table(table_id)
    end

    # データをテーブルに保存する
    # @param table_id [String] テーブル名
    # @param data [Array<Array<String>>] テーブルに登録する二次元配列のデータ
    #
    def load_data(table_id, data)
      # アップロードするCSVファイルを一時ファイルとして作成する
      Tempfile.open(['bq_', '.csv']) do |file|
        # データをCSV形式で一時ファイルに書き込む
        data.each do |row|
          record = CSV.generate_line(row, {force_quotes: true, row_sep: "\r\n"})
          file.write(record)
        end

        # CSVフィルをアップロードする
        file.rewind
        self.table(table_id).load file
      end
    end

    private

    # データセット取得
    # @return [Google::Cloud::Bigquery::Dataset] データセット
    #
    def get_dataset
      @project.dataset(@dataset_name)
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

    # テーブルがすでに存在するエラーかどうかを判定
    # @param e [Exception] 例外
    # @param table_name [String] テーブル名
    # @return [Boolean] テーブルがすでに存在するエラーの場合にtrue
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

  end
end
