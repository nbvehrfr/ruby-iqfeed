require 'socket'
require 'observer'

module Iqfeed
	class Level1Observer
		attr_accessor :symbol

		def initialize(symbol)
			@symbol = symbol
		end

		def update(tick)
			puts tick.to_s
		end
	end

	class Level1Tick
		attr_accessor :type, :time_stamp, :last_price, :total_volume, :last_size, :bid, :ask
		def self.parse(line)
			fields = line.split(',')
			tick = Level1Tick.new
			tick.type = fields[17]
			tick.bid = fields[10]
			tick.ask = fields[11]
			tick.last_price = fields[3]
			tick.last_size = fields[7]
			tick.total_volume = fields[6]
			tick.time_stamp = fields[65]
			tick.type =~ /t/ ? tick : nil
		end

		def to_s
#			if (@type =~ /b/)
#				"Bid: #{@bid_size}@#{@bid}"
#			elsif (@type =~ /a/)
#				"Ask: #{@ask_size}@#{@ask}"
			if (@type =~ /t/)
				"Timestamp:#{@time_stamp} LastPrice:#{@last_price} LastSize:#{@last_size} TotalVolume:#{@total_volume} Bid:#{@bid} Ask:#{@ask}"			
#			elsif (@type =~ /T/)
#				"extendedTrade"
#			elsif !@type.nil?
#				"other"
#			else
#				nil
			end			
		end
	end

	class Level1Client
		include Observable

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

		def add(observer)
			@socket.puts "w" + observer.symbol
			add_observer(observer)
		end

		def remove(symbol)
			@socket.puts "r" + symbol;
		end

		def run
			exception = nil
			while line = @socket.gets
				if line =~ /^E,/
					exception = 'No Data'
				elsif line =~ /!ENDMSG!,/
					break
				end
				tick = Level1Tick.parse(line)
				next if tick.nil?
				changed
				notify_observers(tick)
			end
			if exception
				raise exception
			end
		end
	end
end
