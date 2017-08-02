require 'active_support'
require 'active_support/core_ext'

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
    #
    def create_table(prefix, now: nil, &block)
      # テーブル名の日付部分を決定
      # 翌日1日分のテーブルを作成する
      target_at = (now.nil? ? Time.now : now) + 1.day
      date_str = target_at.strftime('%Y%m%d')

      # データセット取得
      dataset = @project.dataset(@dataset_name)

      # 時間別テーブル作成
      (0 .. 23).each do |hour|
        table_name = "#{prefix}_#{date_str}_#{hour}"

        begin
          # テーブル作成
          dataset.create_table(table_name) do |table|
            table.schema do |schema|
              block? ? block(schema) : default_schema(schema)
            end
          end

        rescue => e
          # テーブルがすでに存在する場合はエラーを無視して次へ進む
          raise e if !duplicate_table?(e, table_name)
          alert(e)
        end
      end
    end

    private

    # ログテーブルにカラムを作成する
    # @param schema [Google::Cloud::Bigquery::Schema] スキーマ
    # @note
    #   service_cd - ログ送信を行ったサービスの名称
    #   created_at - ログの送信日時
    #   realm_cd - レルム
    #   sender_id - 送信元を識別する数値
    #   message_content - ログの内容、GROUP BYに指定できる内容がよい
    #   log_json - ログの詳細、JSON形式で保存する
    #   notify_json - 通知先の情報、{"channel":"general","username":"batch"} など
    #
    def default_schema(schema)
      schema.string 'service_cd', mode: :required
      schema.string 'realm_cd', mode: :required
      schema.integer 'sender_id', mode: :required
      schema.timestamp 'created_at', mode: :required
      schema.string 'message_content', mode: :required
      schema.string 'log_json', mode: :required
      schema.string 'notify_json', mode: :required
    end

    # テーブルがすでに存在するエラーかどうかを判定
    # @param e [Exception] 例外
    # @param table_name [String] テーブル名
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
