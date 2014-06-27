require '../lib/history_client'

c = IQ::HistoryClient.new({})
c.open
# 1 day of tick history
c.get_tick_days('@EU#', 1) do |line|
	puts IQ::Tick.parse(line).to_s
end
