require 'socket'

module IQ
	class Level1Tick
		attr_accessor :type, :symbol, :last, :change, :percent_change, :total_volume, :incremental_volume, :high, :low, :bid, :ask, :bid_size, :ask_size, :tick, :bid_tick
		def self.parse(line)
			fields = line.split(',')
			tick = Level1Tick.new
			tick.type = fields[17]
			tick.bid = fields[10]
			tick.bid_size = fields[12]
			tick.ask = fields[11]
			tick.ask_size = fields[13]
			tick.tick = fields[14]
			tick.last = fields[3]
			tick.incremental_volume = fields[7]
			tick
		end

		def to_s
			if (@type =~ /b/)
				"Bid: #{@bid_size}@#{@bid}"
			elsif (@type =~ /a/)
				"Ask: #{@ask_size}@#{@ask}"
			elsif (@type =~ /t/)
				"Trade: #{@last} #{@incremental_volume}"
			elsif (@type =~ /T/)
				"extendedTrade"
			elsif !@type.nil?
				"other"
			else
				nil
			end			
		end
	end

	class Level1Client
		def initialize(options = {})
			parse_options(options)			
		end

		def parse_options(options)
			@host = options[:host] || 'localhost'
			@port = options[:port] || 5009
			@name = options[:name] || 'DEMO'
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
				yield Level1Tick.parse(line)				
			end
			if exception
				raise exception
			end
		end
	end
end