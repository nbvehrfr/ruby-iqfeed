require 'socket'
require 'observer'

module Iqfeed
	class Level1Observer
		attr_accessor :symbol, :bid, :ask

		def initialize(symbol)
			@symbol = symbol
		end

		def update(tick)
			@bid = tick.bid if @bid.nil? && tick.type =~ /(t|b)/
			@bid = tick.bid if tick.type =~ /b/
			@ask = tick.ask if @ask.nil? && tick.type =~ /(t|a)/
			@ask = tick.ask if tick.type =~ /a/
			puts tick.to_s(@bid, @ask) if tick.sym == @symbol && tick.type =~ /t/
		end
	end

	class Level1Tick
		attr_accessor :type, :time_stamp, :last_price, :total_volume, :last_size, :bid, :ask, :sym
		def self.parse(line)
			fields = line.split(',')
			tick = Level1Tick.new
			tick.type = fields[17]
			tick.sym = fields[1]
			tick.bid = fields[10]
			tick.ask = fields[11]
			tick.last_price = fields[3]
			tick.last_size = fields[7]
			tick.total_volume = fields[6]
			tick.time_stamp = fields[65]
			tick.type =~ /(t|a|b)/ ? tick : nil
		end

		def to_s(bid, ask)
			if (@type =~ /t/)
				if @last_price == @bid
					operation = 'SELL'
				elsif @last_price == @ask
					operation = 'BUY'
				elsif @last_price == bid
					operation = 'SELL'
				elsif @last_price == ask
					operation = 'BUY'
				else
					operation = 'UNKNOWN'
				end
				"Symbol: #{@sym} TS:#{@time_stamp} Size:#{@last_size} Price:#{@last_price} Bid:#{@bid} Ask:#{@ask} #{operation}"
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
