module UvUtil2
  module DbUtil
    def self.make_db(connect)
      res = Sequel.connect(connect, after_connect: proc{|conn| conn.set_error_verbosity(PG::PQERRORS_VERBOSE)})
      res.extension :pg_array, :pg_json
      res
    end
  end
end
