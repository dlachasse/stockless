require "bundler/gem_tasks"
require 'fileutils'

require_relative "./lib/stockless/process_killer.rb"
require_relative "./lib/stockless/middleman.rb"
require_relative "./lib/stockless/db.rb"

namespace :email do

	desc "Check email for new items"
	task :check do
		MiddleMan.new(:receive)
	end

	desc "Send email with item update"
	task :send, :sku do |t, args|
		sku = args[:sku]
		MiddleMan.new(:send, :sku => sku)
	end

	desc "Send email with instructions"
	task :instructions do
		MiddleMan.new(:instructions)
	end

	desc "Add new user"
	task :new_user, :email do |t, args|
		email = args[:email]
		MiddleMan.new(:config, :property => :email, :property_value => email)
	end
	
end

namespace :schedule do

	desc "Update schedule"
	task :update, :increment do |t, args|
		increment = args[:increment]
		MiddleMan.new(:config, :property => :increment, :property_value => increment)
	end

	desc "Restart scheduler"
	task :restart do
		Rake::Task['schedule:stop'].invoke
		schedule_file = Dir.pwd + '/lib/stockless/schedule.rb'
		puts "Reloading schedule"
		load "#{schedule_file}"
	end

	desc "Stop scheduler"
	task :stop do
		ProcessKiller.go
	end

	desc "Start scheduler"
	task :start do
		schedule_file = Dir.pwd + '/lib/stockless/schedule.rb'
		puts "Loading schedule"
		load "#{schedule_file}"
	end

end

namespace :run do

	desc "Run manual check of Visr.net"
	task :check do
		Check.new
	end

end

namespace :db do

	desc "Drop table"
	task :drop do
		DB.new(:drop)
	end

	desc "Close and unlock database"
	task :unlock do
		sql = SQLite3::Database.new File.expand_path('../../product.db')
		sql.close
		puts "DB closed? #{sql.closed?}"
	end

	desc "Insert empty skus"
	task :find_skus do
		DB.new(:insert_skus)
	end

end
