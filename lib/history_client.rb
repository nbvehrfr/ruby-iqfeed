require 'socket'

# TODO
# 1. General parser
# 2. Future contracts joiner

module IQ
	class Tick
		attr_accessor :time_stamp, :last_price, :last_size, :total_volume, :bid, :ask, :tick_id
		
		def self.parse(line)
			tick = Tick.new
			fields = line.split(',')
			tick.time_stamp = fields[0]
			tick.last_price = fields[1]
			tick.last_size = fields[2]
			tick.total_volume = fields[3]
			tick.bid = fields[4]
			tick.ask = fields[5]
			tick			
		end 

		def to_s
			puts "Timestamp:#{@time_stamp} LastPrice:#{@last_price} LastSize:#{@last_size} TotalVolume:#{@total_volume} Bid:#{@bid} Ask:#{@ask}"
		end
	end

	class OHLC
		attr_accessor :time_stamp, :high, :low, :open, :close, :total_volume, :period_volume
		
		def self.parse(line)
			tick = Tick.new
			fields = line.split(',')
			tick.time_stamp = fields[0]
			tick.high = fields[1]
			tick.low = fields[2]
			tick.open = fields[3]
			tick.close = fields[4]
			tick.total_volume = fields[5]
			tick.period_volume = fields[6]
			tick			
		end 

		def to_s
			puts "Timestamp:#{@time_stamp} High:#{@high} Low:#{@low} Open:#{@high} Close:#{@low} TotalVolume:#{@total_volume} PeriodVolume:#{@total_volume}"
		end
	end

	class DWM # day, week, month
		attr_accessor :time_stamp, :high, :low, :open, :close, :period_volume, :open_interest
		
		def self.parse(line)
			tick = Tick.new
			fields = line.split(',')
			tick.time_stamp = fields[0]
			tick.high = fields[1]
			tick.low = fields[2]
			tick.open = fields[3]
			tick.close = fields[4]
			tick.period_volume = fields[5]
			tick.open_interest = fields[6]
			tick			
		end 

		def to_s
			puts "Timestamp:#{@time_stamp} High:#{@high} Low:#{@low} Open:#{@high} Close:#{@low} TotalVolume:#{@total_volume} PeriodVolume:#{@total_volume}"
		end
	end

	class HistoryClient
		attr_accessor :max_tick_number, :start_session, :end_session, :old_to_new, :ticks_per_send

		def initialize(options)
			@host = options[:host] || 'localhost'
			@port = options[:port] || 9100
			@name = options[:name] || 'DEMO'
			@max_tick_number = options[:max_tick_number] || 50000
			@start_session = options[:start_session] || '000000'
			@end_session = options[:end_session] || '235959'
			@old_to_new = options[:old_to_new] || 1 		
			@ticks_per_send = options[:ticks_per_send] || 500
			@request_id = 0
		end

		def open
			@socket = TCPSocket.open @host, @port
			@socket.puts "S,SET CLIENT NAME," + @name
		end

		def process_request(req_id)
			exception = nil			
			while line = @socket.gets
				next unless line =~ /^#{req_id}/
				line.sub!(/^#{req_id},/, "") 
				if line =~ /^E,/
					exception = 'No Data'
				elsif line =~ /!ENDMSG!,/
					break
				end
				yield line
			end
			if exception
				raise exception
			end
		end

		def format_request_id(type)
			type.to_s + @request_id.to_s.rjust(7, '0')
		end

		def get_tick_days(ticket, days, &block)
			@socket.printf "HTD,%s,%07d,%07d,%s,%s,%d,0%07d,%07d\r\n", 
				ticket, days, 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			
			process_request(format_request_id(0)) do |line|
				block.call line
			end
			@request_id = @request_id + 1
		end

		def get_tick_range(ticket, start, finish, &block)
			@socket.printf "HTT,%s,%s,%s,%07d,%s,%s,%d,0%07d,%07d\r\n", 
				ticket, start.strftime("%Y%m%d %H%M%S"), finish.strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send

			process_request(format_request_id(0)) do |line|
				block.call line
			end
			@request_id = @request_id + 1
		end

		def get_daily_range(ticket, start, finish, &block)
			@socket.printf "HDT,%s,%s,%s,%07d,%d,2%07d,%07d\r\n", 
				ticket, start.strftime("%Y%m%d %H%M%S"), finish.strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @old_to_new, @request_id, @ticks_per_send

			process_request(format_request_id(2)) do |line|
				block.call line
			end
			@request_id = @request_id + 1
		end

		def get_ohlc_days(ticket, interval_in_seconds, days, &block)
			@socket.printf "HID,%s,%07d,%07d,%07d,%s,%s,%d,1%07d,%07d\r\n", 
				ticket, interval_in_seconds, days, 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			
			process_request(format_request_id(1)) do |line|
				block.call line
			end
			@request_id = @request_id + 1
		end

		def get_ohlc_range(ticket, interval_in_seconds, start, finish, &block)
			@socket.printf "HIT,%s,%07d,%s,%s,%07d,%s,%s,%d,1%07d,%07d\r\n", 
				ticket, interval_in_seconds, start.strftime("%Y%m%d %H%M%S"), finish.strftime("%Y%m%d %H%M%S"), 
				@max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send

			process_request(format_request_id(1)) do |line|
				block.call line
			end
			@request_id = @request_id + 1
		end

		def close
			@socket.close
		end
	end
end