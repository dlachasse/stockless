require 'watir-webdriver'
require_relative './db'
require_relative './middleman'

class Check

	def initialize
		puts "\033[33mCHECK\033[0m :: Running"
		@db_file = File.join(File.dirname(File.expand_path("./stockless/")), 'product.db')
		@added_sku = Array.new
		
		client = Selenium::WebDriver::Remote::Http::Default.new
		client.timeout = 180 # seconds – default is 60
		@b = Watir::Browser.new :firefox, :http_client => client

		@b.driver.manage.timeouts.implicit_wait = 5
		@b.goto("https://www.visr.net/msib21vb")
		@b.text_field(:name => "Loginform1:UserName").set 'visr8979'
		@b.text_field(:name => "Loginform1:Password").set 'f5zd58vzxf5'
		@b.button(:name => "Loginform1:Login_Command").click
		if @b.url.match /(aspxerror|NotAvailable)/
			@b.goto("https://www.visr.net/msib21vb")
		end

		SQLite3::Database.new @db_file do |db|
			db.execute "SELECT * FROM items" do |row|

				sup_sku = "0" * 8
				sup_sku += row[0]
				sup_sku = sup_sku[sup_sku.length - 14..-1]
				current_inventory = row[2].to_i
				@b.text_field(:id => "pageHeader_SLDSearchControl1_searchInput").set sup_sku
				@b.button(:id => "pageHeader_SLDSearchControl1_searchSubmit").click
				upc = sup_sku.to_i
				if @b.table(:id => "dlistProducts").td(index: 0).a(index: 0).exists?
					@b.table(:id => "dlistProducts").td(index: 0).a(index: 0).click
					@b.driver.manage.timeouts.implicit_wait = 5
					@b.table(:id => "dlColorList").links.each { |color| color.click }
					@b.trs(:class, "dataTableRowBg").each do |trow|
						if trow.text.include? sup_sku
							quantity = trow[6].text.to_i
							if current_inventory != quantity
								puts "\033[32mSQL\033[0m :: UPDATE items SET quantity = #{quantity} WHERE upc = '#{upc}'"
								result = db.prepare("UPDATE items SET quantity = #{quantity} WHERE upc = '#{upc}'").execute
								if current_inventory + 5 < quantity
									@added_sku << row[1]
								end
							end
						end
						close_result result
					end
				else
					unless current_inventory == 0
						puts "\033[32mSQL\033[0m :: UPDATE items SET quantity = 0 WHERE upc = '#{upc}'"
						result = db.prepare("UPDATE items SET quantity = 0 WHERE upc = '#{upc}'").execute
					end
				end

				close_result result
			end

			@b.close
		end

		MiddleMan.new(:send, :sku => @added_sku) unless @added_sku.empty?

	rescue Watir::Exception::UnknownObjectException, Net::ReadTimeout
		@b.close
		puts "\033[31mERROR\033[0m :: Error on webpage"

	end

	def close_result res
		res.close if res
	end

end
