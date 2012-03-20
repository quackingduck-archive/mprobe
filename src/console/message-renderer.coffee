###

The client code that renders incoming messages. Initial users of mprobe will
probably have to customize this manually until some patterns emerge.

###

# the core message rendering function
m = (msg) ->
  {meta, header, body} = msg
  {headerHtml, bodyHtml} = process msg

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

  if typeof header is 'object'
    if header.test_suite
      x.headerHtml = "<span class='test-suite'>test suite</span>"
      x.bodyHtml = "<span class='test-suite'>#{header.test_suite}</span>"

  else if typeof body is 'string'
    # todo, html escape
    x.bodyHtml = body

  return x

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

# called when the console starts, good place to bind click handlers
boot = ->
  # sometimes you have to click this guy twice
  document.getElementById('follow-messages').addEventListener 'click', ->
    scollToBottom()
