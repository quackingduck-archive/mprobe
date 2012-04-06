###

`mprobe` (with no args) starts a broker, then starts the console, then opens
a browser window to it. boom.

###

net = require 'net'
http = require 'http'
{spawn} = require 'child_process'

probeName = process.env.MPROBE or 'mprobe'

@run = (rawArgs) ->
  args = parseArgs rawArgs

  exit 0, usage if args.help?
  exit 1, versionNumber if args.version?

  if args.demo?
    require '../examples/demo'
    return

  c = net.connect "/tmp/#{probeName}-pull"

  # Detect if the broker was already started
  c.on 'connect', ->
    console.log "- connected to broker at /tmp/#{probeName}-pub"
    c.destroy()
    startConsole()

  # Otherwise start it first
  c.on 'error', ->
    startBroker()
    startConsole()

# ---

startConsole = ->
  console.log "- starting console"
  findOpenPortGreaterThan 8000, (port) ->
    mpConsole = require './console/console'
    mpConsole.run port, ->
      # require('fs').writeFileSync "/tmp/#{probeName}-touch", '' # for dev
      # spawn 'open', ["http://localhost:#{port}"]

startBroker = (cb) ->
  require "./broker"

# ---

findOpenPortGreaterThan = (port, cb) ->
  portFree port, (free) ->
    if free then cb(port) else findOpenPortGreaterThan ++port, cb

portFree = (port, cb) ->
  c = net.connect port
  c.on 'error',   -> c.destroy() ; cb yes
  c.on 'connect', -> c.destroy() ; cb no

# ---

dir = __dirname
npmBinDir = "#{dir}/../node_modules/.bin"

# ---

# convert array of strings into data structure
parseArgs = (rawArgs) ->
  # todo: version
  first = rawArgs[0]
  switch first
    when '--help', '-h'  then { help: yes }
    when '--version'     then { version: yes }
    when '--demo'        then { demo: yes }
    else {}

exit = (status, message) ->
  console.log message if message?
  process.exit status

versionNumber = JSON.parse(
  require('fs').readFileSync("#{dir}/../package.json")
).version

# todo: use real version
usage = """
Mprobe v#{versionNumber}

To start the console:

  MPROBE=myproject mprobe

To send some demo messages to test it's working:

  MPROBE=myproject mprobe --demo
"""
