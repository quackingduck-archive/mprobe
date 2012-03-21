###

The client code that renders incoming messages. Initial users of mprobe will
probably have to customize this manually until some patterns emerge.

This is where mprobe decides what "type" a message is. In fact, this is where
mprobe does most of its interesting work.

###

# the core message rendering function
m = (msg) ->
  {meta, header, body} = msg
  {rowClass, headerHtml, bodyHtml} = process msg

  lastTimeActivitySeenFromServer = new Date

  scrolledToBottom = scrollBottom() is totalHeight()

  document.write """
  <div class="row #{rowClass or ''}">
    <span class="header"><span class="wrap">#{headerHtml or header}</span></span>
    <span class="separator"><span class="wrap">»</span></span>
    <span class="body"><span class="wrap">#{bodyHtml or JSON.stringify body}</span></span>
    <span class="timestamp"><span class="wrap">#{formatTime meta.timestamp}</span></span>
  </div>
  """

  scollToBottom() if scrolledToBottom

# can't think of a better name for this, also not sure if this is the right implementation
process = (msg) ->
  {meta, header, body} = msg
  x = {}

  # an alternative to this if statement would be iterating over of a list
  # of user provided processors
  if typeof header is 'object'
    if header.test_suite?
      x.headerHtml = "<span class='test-suite'>test suite</span>"
      x.bodyHtml = "<span class='test-suite'>#{header.test_suite}</span>"

    else if header.test_start?
      x.headerHtml = "<span class='test-start'>test start</span>"
      x.bodyHtml = "<span class='test-start'>#{header.test_start}</span>"
      store.testStarts[header.id] = meta.timestamp

    else if header.test_end?
      ms = meta.timestamp - store.testStarts[header.test_end.id]
      x.headerHtml = "<span class='test-end'>test end</span>"
      x.bodyHtml = "<span class='test-end'>completed in: #{ms}ms</span>"

    else if header.sql?
      x.rowClass = 'sql'
      x.headerHtml = "<span>sql#{if header.params? then ' <small>( + params)</small>' else ''}</span>"
      x.bodyHtml = "<span>#{header.sql} #{if header.params? then JSON.stringify(header.params) else ''}</span>"

    else if header.request_start?
      store.reqStarts[header.request_start] = meta.timestamp
      x.rowClass = 'request'
      x.headerHtml = "<span>request - start</span>"
      x.bodyHtml = "<span>#{header.method} #{header.url}</span>"

    else if header.request_end?
      ms = meta.timestamp - store.reqStarts[header.request_end]
      x.rowClass = 'request'
      x.headerHtml = "<span>request - end</span>"
      x.bodyHtml = "<span>#{ms}ms #{header.url}</span>"

    else if header.boot?
      x.rowClass = 'boot'
      x.headerHtml = "<span>boot</span>"
      x.bodyHtml = "<span>#{header.boot}</span>"

    else
      x.rowClass = 'probe'
      x.headerHtml = "<span class='probe'>probe</span>"
      x.bodyHtml = "<span class='probe'>#{JSON.stringify header}</span>"


  else if (typeof header is 'string') and not body?
    x.rowClass = 'probe'
    x.headerHtml = "<span class='probe'>probe</span>"
    x.bodyHtml = "<span class='probe'>#{e header}</span>"

  else if typeof body is 'string'
    # todo, html escape
    x.bodyHtml = e body

  return x

store =
  testStarts: {}
  reqStarts: {}


formatTime = (ms) ->
  d = new Date ms
  "'#{padInt d.getMinutes(), 2}:#{padInt d.getSeconds(), 2}:#{padInt d.getMilliseconds(), 3}"

padInt = (int, length) ->
  str = '' + int
  str = '0' + str while str.length < length
  str

e = (str) ->
  str.
    replace(/&/g, '&amp;').
    replace(/</g, '&lt;').
    replace(/>/g, '&gt;').
    replace(/"/g, '&quot;')

# ---

# the scrollpoint plus the height of the window
scrollBottom = -> window.innerHeight + window.scrollY
scollToBottom = -> window.scrollTo(0, document.body.scrollHeight - window.innerHeight)
totalHeight = -> document.body.scrollHeight

# ---

# Assume the browser closed the connection and refresh the browser window
# after a long period of no messages. Ideally, I'd like the browser to keep
# the connection open forever but haven't figured out how

lastTimeActivitySeenFromServer = new Date

setInterval ->
  duration = (new Date) - lastTimeActivitySeenFromServer
  if duration > (2 * 1000 * 60) # 2mins
    window.location.reload()
, 200

# ---

# called when the console starts, good place to bind click handlers
boot = ->
  # sometimes you have to click this guy twice
  document.getElementById('follow-messages').addEventListener 'click', ->
    scollToBottom()

