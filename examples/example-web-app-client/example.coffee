###

What using mprobe from an express app might look like.

###

probe = require '../../src/mprobe'

console.log "PROBE env not set, probes are disabled" unless process.env.PROBE?

setTimeout ->
  probe test_suite: "invites"
  probe test_start: "findOrCreateByEmail", id: 1
  probe { some: 'structure' }
  probe sql: 'SELECT id FROM invites WHERE email = $1 LIMIT 1', params: [ 'myles@myles.id.au' ]
  probe 'a label', "string value"
  probe "a truncated label", "a truncated stringy string sttring stringy string sttring stringy string sttring stringy string sttring stringy string string"
  probe test_end: id: 1
, 500

console.log 'client running'
