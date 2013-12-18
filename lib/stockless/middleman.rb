require 'gmail'
require 'yaml'
require 'maruku'
require 'nokogiri'

require_relative './db'
require_relative './check'
CNF = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml'))

class MiddleMan

	def initialize(action, opts={})
		@gmail = Gmail.new(CNF['email_user'], CNF['email_pass'])
		case action
		when :send
			send opts[:sku] if opts[:sku]
		when :receive
			receive
		when :instructions
			send_instructions
		when :config
			config_adjust opts[:property], opts[:property_value]
		end
	end

	def send sku
		puts "\033[35mMESSAGE\033[0m :: Preparing message"
		data = DB.new(:build_response)
		table = data.instance_variable_get('@resp_body')
		sku = sku.join(", ") if sku.is_a? Array

		# This will build a new text message sent
		# from Twilio once account is activated
		#
		# Message.new("New #{sku} in stock!")

		html = build_html sku, table

		CNF['email_list'].each do |address|
			@gmail.deliver do |email|
			  email.to "#{address}"
		  	email.subject "Visr inventory :: New Inventory!"
			  email.html_part do 
			  	body html
				end

			end

		end

		puts "\033[35mMESSAGE\033[0m :: Message delivered"
	end

	def receive
		if @gmail.inbox.count(:unread) > 0
			puts "\033[35mMESSAGE\033[0m :: Receiving message(s)"
			@gmail.inbox.emails(:unread).each do |email|
				sender = email.envelope.from.first["mailbox"] + "@" + email.envelope.from.first["host"]
				message = email.body.to_s

				html_body = extract_html(message)
				text = extract_text(html_body)
				puts "\033[35mMESSAGE\033[0m :: #{text}"

				case text
				when /^\d+/
					build text
				when /^send instructions/
					send_instructions sender
				when /^schedule:/
					update_schedule text
				when /user/
					address = text.match(/\S+@\S+\.(com|net|org)/i)[0]
					config_adjust :email, address
				else
					puts "Nothing to do!"
				end
			end
		else
			puts "\033[35mMESSAGE\033[0m :: No new emails"
		end
	end

	def extract_html body
		beginning = body.index("<div")
		eoh = body.index("</div>") + 6
		body[beginning..eoh]
	end

	def extract_text html
		body = Nokogiri::HTML(html)
		body.css("div").text.strip
	end

	def build email
		upcs = email[-1] != "," ? email += "," : email
		upcs = upcs.gsub("\n\n","").split(",").map { |s| s.to_s }
		upcs.reject! { |s| s.empty? }

		DB.new(:insert, :upc => upcs)

		Check.new
	end

	def send_instructions address
		puts "Sending instructions to #{address}"
		instructions = File.read(File.join(File.dirname(File.expand_path("stockless/")), 'README.md'))
		doc = Maruku.new(instructions)
		@gmail.deliver do |email|
			puts "Delivering instructions :: #{doc.to_html}"
			email.to address
		  email.subject "Visr Checker instructions"
		  email.html_part do
		  	body "#{doc.to_html}"
		  end
		end
		puts "Instructions delivered!"
	end

	def update_schedule email
		interval = /(\d+)/.match(email).to_i
		system("start rake schedule:update[#{interval}]")
	end

	def config_adjust property, property_value
		output_file = Dir.pwd + '/lib/stockless/config.overwrite.yml'
		input_file = Dir.pwd + '/lib/stockless/config.yml'
		File.open(output_file, 'w') do |out_file|
			File.open(input_file, 'r+') do |in_file|
				in_file.each_line do |line|
					if /^email_list:/ =~ line && property == :email
						out_file.puts line.insert(line.length - 2, ",'#{property_value}'")
					elsif /^schedule:/.match(line[0..8]) && property == :increment
						out_file.puts "schedule: #{property_value}"
					else
						out_file.puts line
					end
				end
			end
		end
		FileUtils.mv(output_file, input_file)
		Rake::Task['schedule:restart'].invoke
	end

	def build_html sku, table
		html = "<h3>Visr Stock Report</h3>
			<p>
				Quantities were pulled from visr.net on #{Time.now.strftime("%A, %B %d at %I:%M%P")}. New <b>#{sku}</b> stock was added!
			</p>
		 <table cellspacing=\"0\" cellpadding=\"10\" border=\"0\">
			<thead>
				<tr style=\"border-bottom: thin solid\">
					<th>UPC</th>
					<th>SKU</th>
					<th>Quantity</th>
				</tr>
			</th>
			<tbody>
				#{table}
		  </tbody>
		</table>"
	end

end
