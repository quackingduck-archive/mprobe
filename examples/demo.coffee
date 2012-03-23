###

Run with

  MPROBE=myproject coffee demo.coffee

or

  MPROBE=myproject mprobe --demo

###

probe = require '../src/mprobe'

probe "a string"
probe "a string"
probe "a string"
probe "a string"
probe "a string"
probe "a string"
probe "a string"
probe "a string"
probe "a string"

console.log "demo messages sent"
process.exit()
