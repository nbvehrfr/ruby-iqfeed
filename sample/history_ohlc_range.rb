require '../lib/history_client'

o = IQ::HistoryObserver.new
c = IQ::HistoryClient.new
c.open
c.get_ohlc_range({:symbol => '@EU#', :duration => 300, :from => Time.now - 200 * 3600, :to => Time.now}, o) 
c.run(1)
