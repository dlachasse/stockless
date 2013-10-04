require 'watir-webdriver'
require_relative './db'
require_relative './middleman'

class Check

	def initialize
		@change = false
		@added_sku = Array.new
		@b = Watir::Browser.new :firefox
		@b.driver.manage.timeouts.implicit_wait = 5
		@b.goto("https://www.visr.net/msib21vb")
		@b.text_field(:name => "Loginform1:UserName").set 'visr8979'
		@b.text_field(:name => "Loginform1:Password").set 'f5zd58vzxf5'
		@b.button(:name => "Loginform1:Login_Command").click

		SQLite3::Database.new "C:/Users/dlachasse/ruby_projects/stockless/product.db" do |db|
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
								puts "SQL :: UPDATE items SET quantity = #{quantity} WHERE upc = '#{upc}'"
								result = db.prepare("UPDATE items SET quantity = #{quantity} WHERE upc = '#{upc}'").execute
								if current_inventory < quantity
									@change = true
									@added_sku << row[1]
								end
							end
						end
						result.close if result
					end
				else
					if current_inventory != 0
						puts "SQL :: UPDATE items SET quantity = 0 WHERE upc = '#{upc}'"
						result = db.prepare("UPDATE items SET quantity = 0 WHERE upc = '#{upc}'").execute
					end
				end

				result.close if result
			end

			@b.close
		end

		if @change == true
			MiddleMan.new(:send, :sku => @added_sku)
		end
	end

end
