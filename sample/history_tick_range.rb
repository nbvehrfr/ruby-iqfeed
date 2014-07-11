require '../lib/history_client'

c = IQ::HistoryClient.new
c.open
# 2 hours of tick history
c.get_tick_range({:symbol => '@EU#', :from => Time.now - 2 * 3600, :to => Time.now}) do |line|
	puts line.to_s
end
