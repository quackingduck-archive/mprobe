mp = require 'message-ports'

pub  = mp.pub  '/tmp/mprobe-pub'
pull = mp.pull '/tmp/mprobe-pull'

pull (msg) -> pub msg

console.log "mprobe broker running"
