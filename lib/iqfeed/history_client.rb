require 'socket'
require 'observer'

module Iqfeed
	class NoDataError < StandardError
		attr_reader :object

		def initialize(object)
			@object = object
		end
	end

	class HistoryObserver
		def initialize()			
		end

		def update(tick)
			puts tick.to_s
		end
	end
	
	class Tick
		attr_accessor :time_stamp, :last_price, :last_size, :total_volume, :bid, :ask, :tick_id
		
		def self.parse(line)
			tick = Tick.new
			fields = line.split(',')
			tick.time_stamp = fields[0].to_s
			tick.last_price = fields[1].to_f
			tick.last_size = fields[2].to_i
			tick.total_volume = fields[3].to_i
			tick.bid = fields[4].to_f
			tick.ask = fields[5].to_f
			tick			
		end 

		def to_s
			"Timestamp:#{@time_stamp} LastPrice:#{@last_price} LastSize:#{@last_size} TotalVolume:#{@total_volume} Bid:#{@bid} Ask:#{@ask}"
		end

		def to_csv
			[@time_stamp, @last_price, @last_size, @total_volume, @bid, @ask].join(';')
		end
	end

	class OHLC
		attr_accessor :time_stamp, :high, :low, :open, :close, :total_volume, :period_volume
		
		def self.parse(line)
			ohlc = OHLC.new
			fields = line.split(',')
			ohlc.time_stamp = fields[0]
			ohlc.high = fields[1]
			ohlc.low = fields[2]
			ohlc.open = fields[3]
			ohlc.close = fields[4]
			ohlc.total_volume = fields[5]
			ohlc.period_volume = fields[6]
			ohlc			
		end 

		def to_s
			"Timestamp:#{@time_stamp} High:#{@high} Low:#{@low} Open:#{@open} Close:#{@close} TotalVolume:#{@total_volume} PeriodVolume:#{@period_volume}"
		end

		def to_csv
			[@time_stamp, @open, @high, @low, @close, @total_volume, @period_volume].join(';')
		end
	end

	class DWM # day, week, month
		attr_accessor :time_stamp, :high, :low, :open, :close, :period_volume, :open_interest
		
		def self.parse(line)
			dwm = DWM.new
			fields = line.split(',')
			dwm.time_stamp = fields[0]
			dwm.high = fields[1]
			dwm.low = fields[2]
			dwm.open = fields[3]
			dwm.close = fields[4]
			dwm.period_volume = fields[5]
			dwm.open_interest = fields[6]
			dwm			
		end 

		def to_s
			"Timestamp:#{@time_stamp} High:#{@high} Low:#{@low} Open:#{@open} Close:#{@close} PeriodVolume:#{@period_volume} OpenInterest:#{@open_interest}"
		end

		def to_csv
			[@time_stamp, @high, @low, @open, @close, @period_volume, @open_interest].join(';')
		end
	end

	class HistoryClient
		include Observable
		attr_accessor :max_tick_number, :start_session, :end_session, :old_to_new, :ticks_per_send

		def initialize(options = {})
			parse_options(options)
			@request_id = 0
		end

		def parse_options(options)
			@host = options[:host] || 'localhost'
			@port = options[:port] || 9100
			@name = options[:name] || 'DEMO'
			@max_tick_number = options[:max_tick_number] || 5000000
			@start_session = options[:start_session] || '000000'
			@end_session = options[:end_session] || '235959'
			@old_to_new = options[:old_to_new] || 1 		
			@ticks_per_send = options[:ticks_per_send] || 500
		end

		def open
			@socket = TCPSocket.open @host, @port
			@socket.puts "S,SET CLIENT NAME," + @name
		end

		def process_request
			procs = []
			exception = nil			

			procs[0] = Proc.new{|line| IQ::Tick.parse(line)}
			procs[1] = Proc.new{|line| IQ::OHLC.parse(line)}
			procs[2] = Proc.new{|line| IQ::DWM.parse(line)}

			while line = @socket.gets
				fields = line.match(/^([^,]+),(.*)/) 
				line = fields[2]
				if line =~ /^E,/
					exception = 'No Data'
				elsif line =~ /!ENDMSG!,/
					break
				end
				yield procs[fields[1][0].to_i].call(line)
			end
			if exception
				raise NoDataError.new("No Data")
			end
		end

		def format_request_id(type)
			type.to_s + @request_id.to_s.rjust(7, '0')
		end
		
		def run
			process_request do |line|
				changed
				notify_observers(line)
			end
			@request_id = @request_id + 1
		end

		def get_tick_range(options, observer)
			printf "HTT,%s,%s,%s,%07d,%s,%s,%d,0%07d,%07d\r\n", 
				options[:symbol], options[:from].strftime("%Y%m%d %H%M%S"), options[:to].strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			@socket.printf "HTT,%s,%s,%s,%07d,%s,%s,%d,0%07d,%07d\r\n", 
				options[:symbol], options[:from].strftime("%Y%m%d %H%M%S"), options[:to].strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			add_observer(observer)			
		end

		def get_daily_range(options, observer)
			@socket.printf "HDT,%s,%s,%s,%07d,%d,2%07d,%07d\r\n", 
				options[:symbol], options[:from].strftime("%Y%m%d %H%M%S"), options[:to].strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @old_to_new, @request_id, @ticks_per_send
			add_observer(observer)			
		end

		def get_ohlc_range(options, observer)
			printf "HIT,%s,%07d,%s,%s,%07d,%s,%s,%d,1%07d,%07d\r\n", 
				options[:symbol], options[:duration], options[:from].strftime("%Y%m%d %H%M%S"), options[:to].strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			@socket.printf "HIT,%s,%07d,%s,%s,%07d,%s,%s,%d,1%07d,%07d\r\n", 
				options[:symbol], options[:duration], options[:from].strftime("%Y%m%d %H%M%S"), options[:to].strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			add_observer(observer)			
		end

		def close
			@socket.close
		end
	end
end
