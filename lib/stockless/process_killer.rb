require 'sys/proctable'

include Sys

class ProcessKiller

	class << self

		def go
			a = ProcTable.ps
			to_kill = Array.new

			a.each do |p|
				if /c:\/RailsInstaller\/Ruby1.9.3\/bin\/rake\sschedule:/ =~ p.cmdline
					to_kill << p.pid
				end
			end

			if to_kill.length > 1
				Process.kill(9, to_kill.first)
			end

		end

	end

end
