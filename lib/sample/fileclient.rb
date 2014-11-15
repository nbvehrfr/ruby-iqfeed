require '../lib/file_client'

o = IQ::FileObserver.new("")
c = IQ::FileClient.new

c.open
c.add(o)
c.run
