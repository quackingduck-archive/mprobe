mp = require 'message-ports'

probeName = process.env.MPROBE or 'mprobe'

pullPath = "/tmp/#{probeName}-pull"
pubPath  = "/tmp/#{probeName}-pub"

pub  = mp.pub  pubPath
pull = mp.pull pullPath

pull (msg) -> pub msg

console.log "- broker listening on #{pullPath} and publishing on #{pubPath}"

