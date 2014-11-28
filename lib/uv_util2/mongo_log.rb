require "moped"

module UvUtil2
  class MongoLog
    def initialize(server_ary, db_name)
      @session = Moped::Session.new(server_ary)
      @session.use db_name
    end

    def get_session
      @session
    end

    def add_log(collection, data)
      data[:insert_ts] = Time.new if !data[:insert_ts]
      @session[collection].insert(data)
    end

    def method_missing(method, *args)
      add_log(method, args[0])
    end
  end
end
