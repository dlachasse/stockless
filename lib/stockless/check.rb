require 'watir-webdriver'
require_relative './db'
require_relative './middleman'

class Check

	def initialize
		puts "\033[33mCHECK\033[0m :: Running"
		@db_file = File.join(File.dirname(File.expand_path("./stockless/")), 'product.db')
		@added_sku = Array.new
		
    create_client
    login
    handle_404

		SQLite3::Database.new @db_file do |db|
			db.execute "SELECT * FROM items" do |row|
        @row = @row
        @current_inventory = @row[2].to_i
        @sup_sku = build_sku(@row[0])
        @sku = @row[1]
				@upc = @sup_sku.to_i
        search
        find_product
				close_result result
			end

			@b.close
		end

		MiddleMan.new(:send, :sku => @added_sku) unless @added_sku.empty?

	rescue Watir::Exception::UnknownObjectException, Net::ReadTimeout
		@b.close
		puts "\033[31mERROR\033[0m :: Error on webpage"

	end

  def find_product
    if @b.table(:id => "dlistProducts").td(index: 0).a(index: 0).exists?
      @b.table(:id => "dlistProducts").td(index: 0).a(index: 0).click
      @b.driver.manage.timeouts.implicit_wait = 3
      @b.table(:id => "dlColorList").links.each { |color| color.click }
      @b.trs(:class, "dataTableRowBg").each do |trow|
      handle_row(trow)
      end
    else
      puts "\033[31mWARN\033[0m :: Item now nonexistent, remove from list"
      puts "\033[32mSQL\033[0m :: DELETE FROM items WHERE @upc = '#{@upc}'"
      result = db.prepare("DELETE FROM items WHERE @upc = '#{@upc}'").execute
    end
  end
  
  def handle_row trow
    if trow.text.include? @sup_sku
      @quantity = trow[6].text.to_i
      update_inventory(db) if @current_inventory != @quantity
        puts "\033[32mSQL\033[0m :: UPDATE items SET quantity = #{quantity} WHERE @upc = '#{@upc}'"
        result = db.prepare("UPDATE items SET quantity = #{quantity} WHERE @upc = '#{@upc}'").execute
        add_to_new_inventory
      end
    end
    close_result result
  end

  def build_sku sku
    @sup_sku = "0" * 8
    @sup_sku += sku
    @sup_sku = @sup_sku[@sup_sku.length - 14..-1]
  end

  def create_client
		client = Selenium::WebDriver::Remote::Http::Default.new
		client.timeout = 180 # seconds – default is 60
		@b = Watir::Browser.new :firefox, :http_client => client
  end

	def close_result res
		res.close if res
	end

  def handle_404
    @b.goto("https://www.visr.net/msib21vb") if @b.url.match /(aspxerror|NotAvailable)/
  end

  def login
		@b.driver.manage.timeouts.implicit_wait = 5
		@b.goto("https://www.visr.net/msib21vb")
		@b.text_field(:name => "Loginform1:UserName").set CNF['site_user']
		@b.text_field(:name => "Loginform1:Password").set CNF['site_pass']
		@b.button(:name => "Loginform1:Login_Command").click
  end

  def add_to_new_inventory
    @added_sku << @sku if @current_inventory + 5 < @quantity
  end

  def search
    @b.text_field(:id => "pageHeader_SLDSearchControl1_searchInput").set @sup_sku
    @b.button(:id => "pageHeader_SLDSearchControl1_searchSubmit").click
  end

end
