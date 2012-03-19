http = require 'http'
fs = require 'fs'
mp = require 'message-ports'
coffee = require 'coffee-script'

responder = null

# ---

httpServer = new http.Server
httpServer.on 'request', (req, res) ->
  return res.end("One browser window per console instance plz") if responder?
  res.write header + '\n'
  responder = res

# todo: pick random port
httpServer.listen 8001, ->
  console.log "running on localhost:8001"
  # todo, start web browser here
  setTimeout (-> fs.writeFileSync '/tmp/reload.txt', 'x'), 100

# ---

mp.messageFormat = 'json'
sub = mp.sub '/tmp/mprobe-pub'
sub (msg) ->
  if responder?
    responder.write renderMessage msg

# ---

header = fs.readFileSync "#{__dirname}/console.html.mustache", 'utf8'
header = header.replace '{{styles}}', fs.readFileSync("#{__dirname}/viewer-styles.css",'utf8')
header = header.replace '{{message_rendering_script}}',
  coffee.compile fs.readFileSync("#{__dirname}/message-renderer.coffee",'utf8'), bare: yes

renderMessage = (msg) -> "<script>renderMessage(#{JSON.stringify msg})</script>" + '\n'
