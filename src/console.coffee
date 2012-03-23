http = require 'http'
fs = require 'fs'

coffee = require 'coffee-script'
mp = require 'message-ports'
mp.messageFormat = 'json'

probeName = process.env.MPROBE or 'mprobe'

@run = (port, cb) ->
  # subscribe to the messages coming from the broker
  sub = mp.sub "/tmp/#{probeName}-pub"
  sub (msg) ->
    # if a "responder" (active browser connection) exists then send it the
    # message, otherwise ignore it
    responder = responders[responders.length-1]
    if responder?
      responder.write renderMessage msg

  # start an http server
  httpServer = new http.Server
  httpServer.on 'request', (req, res) ->
    responders.shift()  # remove any previous responder
    res.write consoleUI # send the ui (html/css/js) to the browser
    responders.push res # make this the responder

  httpServer.listen port, ->
    console.log "- console running on http://localhost:#{port}"
    cb()

# ---

# Every http request (including those that happen when the user refreshes the
# browser window of their current console) shifts off the old responder and
# pushes on the new one. So this array is basically a very fancy variable
responders = []

# ---

renderMessage = (msg) ->
  # prevent browsers from running embedded script tags
  # this is a pretty dirty hack, theres' probably some better way to do this
  str = JSON.stringify msg
  str = str.replace ///<script>///g, "<scr|pt>"
  str = str.replace ///</script>///g, "</scr|pt>"
  "<script>m(#{str})</script>" + '\n'

versionNumber = JSON.parse(
  require('fs').readFileSync("#{__dirname}/../package.json")
).version

# poor mans mustache
consoleUI =
  fs.readFileSync("#{__dirname}/console.html.mustache", 'utf8').
  replace(///{{probe_name}}///g, probeName).
  replace(///{{version_number}}///g, versionNumber).
  replace(///{{styles}}///g, fs.readFileSync "#{__dirname}/console.css", 'utf8').
  replace(///{{message_rendering_script}}///g,
    coffee.compile fs.readFileSync("#{__dirname}/console-client.coffee",'utf8'), bare: yes)
