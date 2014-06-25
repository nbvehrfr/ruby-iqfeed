require 'socket'

module IQ
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

		def getDays(ticket, days)
			req_id = @request_id.to_s.rjust(7, '0')
			exception = nil
			
			@socket.printf "HTD,%s,%07d,%07d,%s,%s,%d,%07d,%07d\r\n", 
				ticket, days, @max_tick_number, @start_session, @end_session, @old_to_new, @request_id, @ticks_per_send
			
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
			
			@request_id = @request_id + 1
			if exception
				raise exception
			end
		end

		def close
			@socket.close
		end
	end
end