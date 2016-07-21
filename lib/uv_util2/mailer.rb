require "mail"
require "socket"

module UvUtil2
  class Mailer
    def initialize(from: "", to: "", subject: "", body: "", host: "127.0.0.1", system_mail_second: 3600)
      @from = from
      @to = to
      @subject = subject
      @body = body
      @host = host
      @system_mail_second = system_mail_second
    end

    def send_mail(from: "", to: "", subject: "", body: "")
      mail = Mail.new
      mail.from = from
      mail.to = to
      mail.subject = subject
      mail.body = body
      mail.charset = 'utf-8'
      mail.delivery_method :smtp, { address: @host, enable_starttls_auto: false }
      mail.deliver!
    end

    def send_system_mail(body: "", subject: "")
      send_mail(from: @from, to: @to, subject: @subject + subject + Socket.gethostname, body: body)
    end

    def make_error_msg(error)
      if error.is_a?(Exception)
        error.class.name + "\n" + error.message + "\n" + error.backtrace.join("\n")
      else
        error.to_s
      end
    end

    def process_error(error, error_ts, subject: "")
      msg = make_error_msg(error)
      now = Time.now
      return error_ts if (!error_ts.nil? && now <= error_ts + @system_mail_second)
      send_system_mail(body: msg, subject: subject)
      now
    end

  end
end

