@run = (rawArgs) ->
  exit 0, usage if rawArgs.length is 0

  args = parseArgs rawArgs

  if      args.broker?  then require './broker'
  else if args.console? then require './console/server'
  else if args.demo?
    process.env.PROBE = 'on'
    require '../examples/example-client-app'
  # unrecognized args
  else exit 1, usage


# convert array of strings into data structure
parseArgs = (rawArgs) ->
  # todo: version
  # todo: help
  first = rawArgs[0]
  switch first
    when 'broker'  then { broker: yes }
    when 'console' then { console: yes }
    when 'demo'    then { demo: yes }
    else {}

exit = (status, message) ->
  console.log message if message?
  process.exit status

usage = """
Mprobe v0.0.1 (early alpha release)

Run the broker
  mprobe broker

Run the console
  mprobe console

Then send probes from your app. To test everything is working you can run
the demo
  mprobe demo
"""
