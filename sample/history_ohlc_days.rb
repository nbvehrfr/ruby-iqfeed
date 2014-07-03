require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
# 2 hours of 5m ohlc history
c.get_ohlc_days('@EU#', 3600, 1) do |line|
	puts line.to_s
end
