require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
puts (Time.now - 1).to_s;
c.get_daily_range('@EU#', Time.now - 1, Time.now) do |line|
	puts line
end
