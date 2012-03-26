###

Run with

  MPROBE=myproject coffee demo.coffee

or

  MPROBE=myproject mprobe --demo

###

probe = require '../src/mprobe'

probe() # naked probe
probe "some string"
probe "string probe", "string probe value"
probe "number probe", 1
probe "object probe", foo: "object probe value"
probe "array probe", [1,2,"three"]

console.log "demo messages sent"
process.exit()
