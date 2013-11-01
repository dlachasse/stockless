require 'rufus-scheduler'
require 'eventmachine'

require_relative './middleman'

EM.run {

  scheduler = Rufus::Scheduler.new

	# Full scheduled report
	scheduler.every "#{CNF['schedule']}" do
		MiddleMan.new(:send)
	end

	# Visr check
	scheduler.every "15m" do
	  Check.new
	end

	# Check for emails
	scheduler.every "5m" do
		MiddleMan.new(:receive)
	end

}
