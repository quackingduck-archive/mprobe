renderMessage = (msg) ->
  {meta, header, body} = msg
  scrolledToBottom = scrollBottom() is totalHeight()

  className = ''
  for modifier in builtInModifiers
    className += ' ' + modifier if meta[modifier]

  document.write """
  <div class="row #{className}">
    <span class="header">#{header}</span>
    <span class="separator">➟</span>
    <span class="body">#{JSON.stringify body}</span>
    <span class="timestamp">#{formatTime meta.timestamp}</span>
  </div>
  """

  scollToBottom() if scrolledToBottom

builtInModifiers = ['highlight','lowlight','error']

formatTime = (ms) ->
  d = new Date ms
  "#{padInt d.getHours(), 2}:#{padInt d.getMinutes(), 2}:#{padInt d.getSeconds(), 2}:#{padInt d.getMilliseconds(), 3}"

padInt = (int, length) ->
  str = '' + int
  str = '0' + str while str.length < length
  str

# the scrollpoint plus the height of the window
scrollBottom = -> window.innerHeight + window.scrollY
scollToBottom = -> window.scrollTo(0, document.body.scrollHeight - window.innerHeight)
totalHeight = -> document.body.scrollHeight

# ---

boot = ->
  # sometimes you have to click this guy twice
  document.getElementById('follow-messages').addEventListener 'click', ->
    scollToBottom()


