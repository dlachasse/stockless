require 'sqlite3'
require_relative './check'
require_relative './middleman'
require_relative './local_database'

class DB

	def initialize(action, opts={})
		@db_file = File.join(File.dirname(File.expand_path("./stockless/")), 'product.db')
		case action
		when :insert
			insert opts[:upc]
		when :build_response
			build_response
		when :drop
			drop_table
		when :insert_skus
			find_skus
		when :backorders
			load_in_backorders
		end

	end

	def insert list
		SQLite3::Database.new @db_file do |db|
			list.each do |upc|

				# Strip trailing empty space
				upc.rstrip!
				if upc.chomp!("d").nil?
					puts "\033[32mSQL\033[0m :: REPLACE INTO items VALUES ( '#{upc}', NULL, NULL )"
					result = db.prepare("REPLACE INTO items VALUES ( #{upc.to_i}, NULL, NULL )").execute
				else
					puts "\033[32mSQL\033[0m :: DELETE FROM items WHERE upc LIKE '%#{upc.to_i}'"
					result = db.prepare("DELETE FROM items WHERE upc LIKE '%#{upc.to_i}'").execute
				end

				result.close
			end

			db.close
		end
		find_skus

	end

	def build_response
		SQLite3::Database.new @db_file do |db|
			@resp_body = ""
			db.execute "SELECT * FROM items ORDER BY sku" do |row|
				@resp_body += "<tr><td width=\"80\">#{row[0]}</td><td width=\"200\">#{row[1]}</td><td>#{row[2] || 0}</td></tr>"
			end

			db.close
		end

		return @resp_body
	end

	def drop_table
		sql = "DELETE FROM items"
		run_sql sql
	end

	def run_sql(sql, batch = false)
		SQLite3::Database.new @db_file do |db|
			if batch
				db.execute_batch sql
			else
				db.execute sql
			end

			db.close
		end

	end

	def find_skus
		@client = LocalDatabase.open
		SQLite3::Database.new @db_file do |db|
			db.execute "SELECT * FROM items WHERE sku IS NULL" do |row|

				result = @client.execute("SELECT LocalSKU FROM [SE Data].[dbo].[InventorySuppliers] WHERE SupplierSKU LIKE '%#{row[0]}'")
				sku = result.each(:first => true)
				if result.affected_rows > 0
					sku = sku[0]["LocalSKU"].gsub!("VisrM_", "")
					puts "\033[32mSQL\033[0m :: UPDATE items SET sku = '#{sku}' WHERE upc = '#{row[0]}'"
					sqlite = db.prepare("UPDATE items SET sku = '#{sku}' WHERE upc = '#{row[0]}'").execute
				else
					puts "\033[35mMESSAGE\033[0m :: SKU #{row[0]} does not exist!"
					puts "\033[32mSQL\033[0m :: DELETE FROM items WHERE upc = '#{row[0]}'"
					sqlite = db.prepare("DELETE FROM items WHERE upc = '#{row[0]}'").execute
				end
				sqlite.close

				db.close
			end

		end

		LocalDatabase.close @client
	end

	def load_in_backorders
		@client = LocalDatabase.open

		result = @client.execute("
			SELECT DISTINCT(od.SKU), iv.SupplierSKU FROM [SE Data].[dbo].[Order Details] AS od
				INNER JOIN [SE Data].[dbo].[InventorySuppliers] AS iv
					ON od.SKU = iv.LocalSKU
					WHERE od.Backordered <> 0
						AND od.Status = 'Item Backordered'
						AND iv.SupplierID = 7
						AND iv.SupplierSKU IS NOT NULL
						AND iv.SupplierSKU LIKE '00%'")
		result.each do |sku|
			sku["SKU"].gsub!("VisrM_", "")
			force_insert sku["SKU"], sku["SupplierSKU"].to_i
		end

		LocalDatabase.close @client
	end

	def force_insert sku, upc
		db = SQLite3::Database.open @db_file
		puts "\033[32mSQL\033[0m :: REPLACE INTO items VALUES ( '#{upc}', '#{sku}', NULL )"
		db.execute "REPLACE INTO items VALUES ( '#{upc}', '#{sku}', NULL )"

		db.close if db
	end
	
end
