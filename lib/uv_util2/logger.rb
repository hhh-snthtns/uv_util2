require 'fluent-logger'

module UvUtil2
  class Logger
    def initialize(config)
      @config = config
      @log = Fluent::Logger::FluentLogger.new(
        @config[:tag], host: @config[:host], port: @config[:port])
    end

    def fatal(msg)
      add(:fatal, msg)
    end

    def error(msg)
      add(:error, msg)
    end

    def warn(msg)
      add(:warn, msg)
    end

    def info(msg)
      add(:info, msg)
    end

    def debug(msg)
      add(:debug, msg)
    end

    def access(msg)
      add(:access, msg)
    end

    def add(log_level, msg)
      res = msg.is_a?(Hash) ? msg : {msg: msg}
      @log.post(log_level.to_s, msg)
    end
  end
end

