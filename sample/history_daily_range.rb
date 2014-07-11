require '../lib/history_client'

c = IQ::HistoryClient.new
c.open
c.get_daily_range({:symbol => '@EU#', :from => Time.now - 1, :to => Time.now}) do |line|
	puts line.to_s
end
