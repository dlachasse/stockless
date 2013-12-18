require 'rufus-scheduler'
require 'eventmachine'

require_relative './middleman'

EM.run {

  scheduler = Rufus::Scheduler.new

	# Full scheduled report
	scheduler.every "24h" do
		DB.new(:backorders)
	end

	# Visr check
	scheduler.every "20m" do
	  Check.new
	end

	# Check for emails
	scheduler.every "10m" do
		MiddleMan.new(:receive)
	end

}
