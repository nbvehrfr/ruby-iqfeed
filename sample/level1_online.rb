require '../lib/level1_client'

o = IQ::Level1Observer.new("@EU#")
c = IQ::Level1Client.new

c.open
c.add(o)
c.run
