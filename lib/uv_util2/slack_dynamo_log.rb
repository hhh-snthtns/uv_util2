require 'securerandom'

module UvUtil2
  class SlackDynamoLog
    def self.make_error_msg(e, len: 3, sep: "\n")
      return "" if e.nil?
      e.message + sep + e.backtrace[0..len].join(sep)
    end

    def initialize(
      table_name: nil,
      channel: nil,
      username: nil,
      mailer: nil,
      logger: nil,
      dynamo: nil,
      is_dev: false
    )
      @dynamo = dynamo
      @mailer = mailer
      @logger = logger
      @is_dev = is_dev
      @table_name = table_name
      @channel = channel
      @username = username
    end

    def get_dynamo
      @dynamo
    end

    def get_logger
      @logger
    end

    def get_mailer
      @mailer
    end

    def error_log(**options)
      error_content = options[:exception] ? UvUtil2::SlackDynamoLog::make_error_msg(options[:exception]) + "\n" : ""
      slack_params = options[:slack_params] ? options[:slack_params] : {}
      content = ""
      options.each_pair do |key, value|
        content = "#{content}#{key}:#{value}\n" if ![:exception, :slack_params].include?(key)
      end
      last_content = error_content + content
      error_log_to_dynamo(last_content, slack_params: slack_params)
      @logger.error(last_content) if @logger
    end

    private
    def is_dev?
      @is_dev
    end

    def make_dynamo_params(content, slack_params: {})
      {
        table_name: @table_name,
        item: {
          uuid: SecureRandom.uuid,
          channel: slack_params[:channel] ? slack_params[:channel] : @channel,
          username: slack_params[:username] ? slack_params[:username] : @username,
          created_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          content: content
        }
      }
    end

    def error_log_to_dynamo(content, slack_params: {})
      return if is_dev?
      begin
        @dynamo.put_item(make_dynamo_params(content, slack_params: slack_params))
      rescue => e
        @error_ts = @mailer.process_error(e, @error_ts) if @mailer
      end
    end
  end
end
