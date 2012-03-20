###

The client code that renders incoming messages. Initial users of mprobe will
probably have to customize this manually until some patterns emerge.

This is where mprobe decides what "type" a message is. In fact, this is where
mprobe does most of its interesting work.

###

# the core message rendering function
m = (msg) ->
  {meta, header, body} = msg
  {headerHtml, bodyHtml} = process msg

  lastTimeActivitySeenFromServer = new Date

  scrolledToBottom = scrollBottom() is totalHeight()

  document.write """
  <div class="row">
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
      x.headerHtml = "<span class='test-end'>test end</span>"
      ms = meta.timestamp - store.testStarts[header.test_end.id]
      x.bodyHtml = "<span class='test-end'>completed in: #{ms}ms</span>"

    else
      x.rowClass = 'probe'
      x.headerHtml = "<span class='probe'>probe</span>"
      x.bodyHtml = "<span class='probe'>#{JSON.stringify header}</span>"


  else if typeof body is 'string'
    # todo, html escape
    x.bodyHtml = body

  return x

store =
  testStarts: {}


formatTime = (ms) ->
  d = new Date ms
  "'#{padInt d.getMinutes(), 2}:#{padInt d.getSeconds(), 2}:#{padInt d.getMilliseconds(), 3}"

padInt = (int, length) ->
  str = '' + int
  str = '0' + str while str.length < length
  str

# ---

# the scrollpoint plus the height of the window
scrollBottom = -> window.innerHeight + window.scrollY
scollToBottom = -> window.scrollTo(0, document.body.scrollHeight - window.innerHeight)
totalHeight = -> document.body.scrollHeight

# ---

lastTimeActivitySeenFromServer = new Date

setTimeout ->
  duration = (new Date) - lastTimeActivitySeenFromServer
  window.location.reload() if duration > (100*60) # 1min
, 1000

# ---

# called when the console starts, good place to bind click handlers
boot = ->
  # sometimes you have to click this guy twice
  document.getElementById('follow-messages').addEventListener 'click', ->
    scollToBottom()

