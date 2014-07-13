require '../lib/history_client'

c = IQ::Level1Client.new
c.open
c.add("MSFT")
c.process_request(1) do |line|
	puts line.to_s
end
