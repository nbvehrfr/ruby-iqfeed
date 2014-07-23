require 'observer'

module IQ
	class VolumeBarObserver

		def initialize(volume_per_bar)
			@volume = 0
			@volume_per_bar = volume_per_bar
			@open = nil
			@high = 0
			@low = 1000000
		end

		def update(tick)			
			if @volume + tick.last_size >= @volume_per_bar
				puts "open=#{@open} high=#{@high} low=#{@low} close=#{tick.last_price} volume=#{@volume_per_bar}"
				@volume = @volume + tick.last_size - @volume_per_bar
				@open = tick.last_price
				@high = tick.last_price
				@low = tick.last_price
			else
				@volume += tick.last_size
				@high = tick.last_price if tick.last_price > @high
				@low = tick.last_price if tick.last_price < @low
				@open = tick.last_price if @open.nil?
			end									
		end
	end
end