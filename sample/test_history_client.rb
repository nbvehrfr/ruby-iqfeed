require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
c.get_days('@EU#', 1) do |line|
	puts line
end