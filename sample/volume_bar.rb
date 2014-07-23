require '../lib/file_client'
require '../lib/volume_bar'

o = IQ::VolumeBarObserver.new(10)
c = IQ::FileClient.new
c.open
c.add(o)
c.run
