require 'socket'

module IQ
	class Level1Client
		def initialize(options = {})
			parse_options(options)			
		end

		def parse_options(options)
		end

		def open
			@socket = TCPSocket.open @host, @port
			@socket.puts "S,CONNECT"
			@socket.puts "S,SET CLIENT NAME," + @name
		end

		def add(symbol)
			@socket.puts "w" + symbol;
		end

		def remove(symbol)
			@socket.puts "r" + symbol;
		end

		def process_request(req_id)
			exception = nil
			while line = @socket.gets
				#next unless line =~ /^#{req_id}/
				#line.sub!(/^#{req_id},/, "") 
				if line =~ /^E,/
					exception = 'No Data'
				elsif line =~ /!ENDMSG!,/
					break
				end
				#yield parse.call(line)
				yield parse.call(line)
			end
			if exception
				raise exception
			end
		end
	end
end