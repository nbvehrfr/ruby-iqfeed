require '../iqfeed'

o = Iqfeed::HistoryObserver.new
c = Iqfeed::HistoryClient.new
c.open

c.get_tick_range({:symbol => '@EU#', :from => Time.now - 10 * 3600, :to => Time.now}, o)
c.run
