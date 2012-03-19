###

Fires off a random probe every 300ms. Useful for demoing and developing Mprobe.

Run with

  PROBE=on coffee example-client-app.coffee

###

probe = require '../src/mprobe'

probes = [
  -> probe "a string", "stringy string"
  -> probe.hl "string", "a highlighted string"
  -> probe.ll "string", "a lowlighted/subdued string"
  -> probe.error "an error"
  -> probe "a number", 1234
  -> probe "an array", [1,2,3,4]
  -> probe "an object", { a: 1, b: 2, c: 3 }
]

random = -> probes[Math.floor(Math.random() * probes.length)]

console.log "PROBE env not set, probes are disabled" unless process.env.PROBE?

# this is the app doing "work" and firing a probe every 300ms

setInterval ->
  random()()
, 300

console.log 'client running'
