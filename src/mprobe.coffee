# This is the node client - i.e. the module required by other node apps to
# send to messages to the broker

mp = require 'message-ports'
mp.messageFormat = 'json'

probeName = process.env.MPROBE or 'mprobe'
push = mp.push "/tmp/#{probeName}-pull"

defaultMeta =
  pid:  process.pid
  argv: process.argv

probe = (args...) ->
  probe._send {}, args...

probe._send = (meta, args...) ->
  meta[k] = v for k,v of defaultMeta
  meta.timestamp = Date.now()
  body = if args.length is 1 then args[0] else args
  push { meta, body }

module.exports = probe
