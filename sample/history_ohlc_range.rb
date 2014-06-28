require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
# 2 hours of 5m ohlc history
c.get_ohlc_range('@EU#', 300, Time.now - 200 * 3600, Time.now) do |line|
	puts IQ::Tick.parse(line).to_s
end
