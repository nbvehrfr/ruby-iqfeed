require '../iqfeed'

o = Iqfeed::HistoryObserver.new
c = Iqfeed::HistoryClient.new
c.open
c.get_ohlc_range({:symbol => '@EU#', :duration => 300, :from => Time.now - 200 * 3600, :to => Time.now}, o) 
c.run
