require "sequel"
require "pg"

class Sequel::DatabaseError
  def db_code
    line = message.split("\n")[0]
    db_code = line[25..29]
  end
end

module UvUtil2
  module Db
    def self.make_db(connect)
      res = Sequel.connect(connect, after_connect: proc{|conn| conn.set_error_verbosity(PG::PQERRORS_VERBOSE)})
      res.extension :pg_array, :pg_json
      res
    end
  end
end
