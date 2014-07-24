require 'observer'

module IQ
	class RangeBarObserver

		def initialize(range_per_bar)
			@volume = 0
			@range_per_bar = range_per_bar
			@open = nil
			@high = nil
			@low = nil
		end

		def update(tick)
			@high = tick.last_price if @high.nil?
			@low = tick.last_price if @low.nil?
			@open = tick.last_price if @open.nil?
			@volume += tick.last_size
			
			if @high - tick.last_price >= @range_per_bar || tick.last_price - @low >= @range_per_bar
				puts "open=#{@open} high=#{@high} low=#{@low} close=#{tick.last_price} volume=#{@volume}"
				@volume = 0
				@open = tick.last_price
				@high = tick.last_price
				@low = tick.last_price
			else    				
				@high = tick.last_price if tick.last_price > @high
				@low = tick.last_price if tick.last_price < @low				
			end									
		end
	end
end