require 'date'
require '../iqfeed'

o = Iqfeed::HistoryObserver.new
c = Iqfeed::HistoryClient.new
c.open

today = Date.today
((today - 120)..today).each do |day|
	from = day.to_time
	to = (day + 1).to_time - 1
	c.get_tick_range({:symbol => '@EU#', :from => from, :to => to}, o)
end
c.run
