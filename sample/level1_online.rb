require '../lib/level1_client'

c = IQ::Level1Client.new
c.open
c.add("@EU#")
c.process_request(1) do |line|
	puts line.to_s
end
