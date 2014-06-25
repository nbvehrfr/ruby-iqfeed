require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
c.getDays('@EU#', 1) do |line|
	puts line
end