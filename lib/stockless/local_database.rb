require 'yaml'
require 'tiny_tds'

class LocalDatabase

	class << self
		def open
			client = TinyTds::Client.new(
				:host => CNF['host'], 
				:port => CNF['port'], 
				:username => CNF['username'], 
				:password => CNF['password'],
				:timeout => CNF['timeout'],
				:tds_version => CNF['tds_version'])
		end

		def close conn
			conn.close
		end

	end

end

LocalDatabase.new
