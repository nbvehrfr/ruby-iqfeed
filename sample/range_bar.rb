require '../lib/file_client'
require '../lib/range_bar'

o = IQ::RangeBarObserver.new(0.0010)
c = IQ::FileClient.new
c.open
c.add(o)
c.run
