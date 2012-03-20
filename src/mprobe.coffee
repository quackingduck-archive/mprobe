# This is the client - i.e. the module required by other node apps to send to
# messages to the broker

# This is probably going to be overdesigned for the first few early versions

mp = require 'message-ports'

mp.messageFormat = 'json'

push = mp.push '/tmp/mprobe-pull'

defaultMeta =
  # process-specific info
  pid: 1234

module.exports = probe = (args...) ->
  probe._send {}, args...

probe.hl = (header, body) ->
  probe._send { highlight: on }, header, body

probe._send = (meta, header, body) ->
  return unless process.env.PROBE?
  meta[k] = v for k,v of defaultMeta
  meta.timestamp = Date.now()
  push { meta, header, body }
