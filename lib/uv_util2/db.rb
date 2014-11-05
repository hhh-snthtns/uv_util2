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

    def make_params(params)
      if !params[:now]
        params[:now] = get_now()
      end
      params
    end

    def get_one(ds, params)
      ds.call(:first, make_params(params))
    end

    def get_list(ds, params)
      ds.call(:select, make_params(params))
    end

    def ps_call(ps, params)
      ps.call(make_params(params))
    end

    def get_now
      nil
    end

  end
end
