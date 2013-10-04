require 'twilio-ruby'

class Message

	def initialize content
		@account_sid = CNF["twilio_acct_sid"]
		@auth_token = CNF["twilio_auth_token"]

		# set up a client to talk to the Twilio REST API
		@client = Twilio::REST::Client.new(@account_sid, @auth_token)

		@account = @client.account
		send content
	end

	def send text
		@message = @account.sms.messages.create({
			:to => CNF["sms_number"], 
			:from => CNF["twilio_acct_number"],
			:body => text
			})
		puts @message
	end

end
