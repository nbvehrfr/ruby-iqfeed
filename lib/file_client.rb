require 'observer'

module IQ
	class FileObserver
		attr_accessor :symbol

		def initialize(symbol)
			@symbol = symbol
		end

		def update(tick)
			puts tick.to_s
		end
	end

	class FileTick
		attr_accessor :time_stamp, :last_price, :last_size, :total_volume, :bid, :ask
		def self.parse(line)
			fields = line.split(';')
			tick = FileTick.new
			tick.time_stamp = fields[0]
			tick.last_price = fields[1]
			tick.last_size = fields[2]
			tick.total_volume = fields[3]
			tick.bid = fields[4]
			tick.ask = fields[5]
			tick
		end

		def to_s
			"Timestamp:#{@time_stamp} LastPrice:#{@last_price} LastSize:#{@last_size} TotalVolume:#{@total_volume} Bid:#{@bid} Ask:#{@ask}"			
		end
	end

	class FileClient
		include Observable

		def initialize(options = {})
			parse_options(options)			
		end

		def parse_options(options)
			@filename = options[:filename] || 'input.csv'			
		end

		def open
			@file = File.open(@filename)
		end

		def add(observer)			
			add_observer(observer)
		end

		def run
			@file.each do | line|
				tick = FileTick.parse(line)
				changed
				notify_observers(tick)
			end
		end
	end
end