require 'rufus-scheduler'
require 'yaml'
require 'eventmachine'

require_relative './middleman'

EM.run {

  scheduler = Rufus::Scheduler::EmScheduler.start_new

	# Default email checker
	scheduler.every "#{CNF['schedule']}" do
		MiddleMan.new(:send)
	end

	# Visr check
	scheduler.every "15m" do
	  Check.new
	end

	scheduler.every "5m" do
		MiddleMan.new(:receive)
	end

}
