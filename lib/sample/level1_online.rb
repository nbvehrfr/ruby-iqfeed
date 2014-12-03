require '../iqfeed'

o1 = Iqfeed::Level1Observer.new("@EU#")
o2 = Iqfeed::Level1Observer.new("@BP#")
o3 = Iqfeed::Level1Observer.new("@CD#")
o4 = Iqfeed::Level1Observer.new("@AD#")
o5 = Iqfeed::Level1Observer.new("@JY#")
o6 = Iqfeed::Level1Observer.new("@SF#")
c = Iqfeed::Level1Client.new

c.open
c.add(o1)
c.add(o2)
c.add(o3)
c.add(o4)
c.add(o5)
c.add(o6)
c.run
