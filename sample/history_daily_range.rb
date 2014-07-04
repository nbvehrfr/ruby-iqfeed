require '../lib/history_client'

c = IQ::HistoryClient.new
c.open
c.get_daily_range('@EU#', Time.now - 1, Time.now) do |line|
	puts line.to_s
end
