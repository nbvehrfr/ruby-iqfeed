require '../lib/history_client'

o = IQ::HistoryObserver.new
c = IQ::HistoryClient.new
c.open
# 2 hours of tick history
c.get_tick_range({:symbol => '@EU#', :from => Time.now - 10 * 3600, :to => Time.now}, o)
c.run
