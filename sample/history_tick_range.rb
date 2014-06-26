require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
# 2 hours of tick history
c.get_tick_range('@EU#', Time.now - 2 * 3600, Time.now) do |line|
	puts line
end
