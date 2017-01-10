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
      error_content = options[:exception] ? UvUtil2::AwsLog::make_error_msg(options[:exception]) + "\n" : ""
      content = ""
      options.each_pair do |key, value|
        content = "#{content}#{key}:#{value}\n" if key != :exception
      end
      last_content = error_content + content
      error_log_to_dynamo(last_content)
      @logger.error(last_content) if @logger
    end

    private
    def is_dev?
      @is_dev
    end

    def make_dynamo_params(content)
      {
        table_name: @table_name,
        item: {
          uuid: SecureRandom.uuid,
          channel: @channel,
          username: @username,
          created_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          content: content
        }
      }
    end

    def error_log_to_dynamo(content)
      return if is_dev?
      begin
        @dynamo.put_item(make_dynamo_params(content))
      rescue => e
        @error_ts = @mailer.process_error(e, @error_ts) if @mailer
      end
    end
  end
end
