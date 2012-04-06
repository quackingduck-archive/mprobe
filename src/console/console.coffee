http = require 'http'
fs = require 'fs'

probeName = process.env.MPROBE or 'mprobe'

@run = (port, cb) ->
  httpServer.listen port, ->
    console.log "- console running on http://localhost:#{port}"

# ---

# The Console App Server

express = require 'express'
mustache = require 'mustache'
coffee = require 'coffee-script'
stylus = require 'stylus'

httpServer = express.createServer()

httpServer.get '/',    (req, res) -> html res
httpServer.get '/css', (req, res) -> css  res
httpServer.get '/js',  (req, res) -> js   res

html = (res) ->
  out = mustache.to_html readFile('console.html.mustache'),
    probe_name: probeName
    version_number: versionNumber
  res.end out

js = (res) ->
  res.setHeader 'Content-Type', 'application/javascript'
  res.end [
    # fancy rendering of json structures
    readFile('vendor/underscore.js')
    readFile('vendor/coffee-script.js')
    readFile('vendor/js2coffee.js')
    # dom node creation, event handling
    readFile('vendor/zepto-v0.8.js')
    # syntax highlighting
    readFile('vendor/prettify-1-Jun-2011.js')
    readFile('vendor/prettify-lang-sql.js')
    # the console client app
    coffee.compile(readFile('console-client.coffee'), bare: yes)
  ].join "\n\n"

css = (res) ->
  res.setHeader 'Content-Type', 'text/css'
  stylus.render readFile('console.stylus'), (err,css) ->
    throw err if err?
    res.end css

readFile = (name) ->
  fs.readFileSync("#{__dirname}/#{name}", 'utf8')

versionNumber = JSON.parse(
  require('fs').readFileSync("#{__dirname}/../../package.json")
).version

# ---

# Gather the web socket connections

WSServer = require('ws').Server
connectedWebSockets = []

wss = new WSServer server: httpServer
wss.on 'connection', (ws) ->
  connectedWebSockets.push ws
  ws.on 'close', ->
    connectedWebSockets.splice connectedWebSockets.indexOf(ws), 1

# ---

# Subscribe to broker messages and publish them to the websocket connections

mp = require 'message-ports'
sub = mp.sub "/tmp/#{probeName}-pub"
sub (msg) -> s.send msg for s in connectedWebSockets
