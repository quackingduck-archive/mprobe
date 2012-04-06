# Methods attached to this are part of the "offical" api
window.mprobe = {}

# ---

ws = new WebSocket "ws://#{window.location.host}"
ws.onmessage = (event) -> processIncomingMessage JSON.parse event.data
ws.onclose = -> console.log "sever closed"

# ---

$('body').on 'click', (event) ->
  row = $(event.target).closest('.row')
  return unless row.length

  id = row.attr('data-id')

  if      $(event.target).closest('.label')     then rows[id].toggleDetails()
  else if $(event.target).closest('.summary')   then rows[id].toggleDetails()
  else if $(event.target).closest('.timestamp') then rows[id].toggleMetaDetails()

# ---

rows = {}
callbacks = {}

# proceed with MindWizardry
processIncomingMessage = (msg) ->
  # create row and add it to the store
  row = new Row msg
  rows[row.id] = row

  for handler in handlers
    if handler.match msg.body
      # link the row to the hanlder that processed it
      row.handler = handler

      # process this row with the handler
      handler.row.call(row) if handler.row?
      handler.summary.call(row.summary) if handler.summary?

      # go through the currently waiting callbacks and try to apply one
      # to this row, if it applies successfully, remove it from callbacks
      for rowId, callback of callbacks
        if handler.name is callback.name
          # now we pull a rabbit from the hat
          result = callback.callback.call rows[rowId], row
          delete callbacks[row.id] unless result is no

      # if this handler provides its own callback, install it to callbacks
      # with a timeout to remove it
      if handler.callback?
        callbacks[row.id] = handler.callback
        setTimeout ->
          delete callbacks[row.id]
        , handler.callback.timeout

      break

  if row.handler?
    row.render()
    $('body').append row.node
  else
    console.log "no hanlder for msg", JSON.stringify row.msg

# ---

class Row

  # much of this feels too fancy

  constructor: (@msg) ->
    @id = msg.meta.timestamp + '-' + Math.random().toString().split('.')[1]
    @node = newRowNode()
    @detailsNode = @node.find('.details')
    @summary = new Summary @

  computeLabel: ->
    @handler?.name or "probe"

  computeClass: ->
    @explicitlySetClass or @computeLabel().replace(/[ ]/g,'-').toLowerCase()

  toggleDetails: ->
    @showingDetails ?= yes
    @renderedDetails ?= no

    if @handler.detailsRenderer?
      @handler.detailsRenderer.call(@, @showingDetails, not @renderedDetails)

    @renderedDetails = yes
    @showingDetails = not @showingDetails

  toggleMetaDetails: ->
    @showingMetaDetails ?= no
    @renderedMetaDetails ?= no

    unless @renderedMetaDetails
      metaNode = newMetaDetailsNode()
      metaNode.find('.pid .value').html prettyPrintOne @msg.meta.pid
      metaNode.find('.argv .value').html prettyPrintOne JSON.stringify @msg.meta.argv
      @node.find('.meta-details').replaceWith metaNode
      @renderedMetaDetails = yes

    @node.find('.meta-details').toggle(@showingMetaDetails = not @showingMetaDetails)

  hide: -> @node.hide()

  render: ->
    @node.data 'id', @id
    @node.addClass @computeClass()
    @node.find('.meta-details').toggle off
    @node.find('.details').toggle off
    @node.find('.timestamp').text formatTime @msg.meta.timestamp
    @node.find('.summary .label').text @computeLabel()
    @summary.render()


class Summary

  constructor: (@row) ->
    @segments = []
    @msg = @row.msg
    @node = @row.node.find '.summary .body'

  addSegment: (name, value, opts = {}) ->
    @segments.push {name, value, label: opts.label, color: opts.color }

  updateSegment: (name, content) ->
    @node.find('.'+ name).text content

  render: ->
    segNodes = for segment in @segments
      segNode = newSegmentNode()
      segNode.addClass segment.name

      if segment.label?
        segNode.find('.label').text segment.label
      else
        segNode.find('.label').remove()

      valNode = segNode.find('.value')

      if segment.color?
        valNode.addClass 'colored'
        if typeof segment.color is 'string'
          valNode.html prettyPrintOne(segment.value, segment.color)
        else
          valNode.html prettyPrintOne(segment.value)
      else
        valNode.text segment.value

      @node.append segNode

# ---

formatTime = (ms) ->
  d = new Date ms
  "'#{padInt d.getMinutes(), 2}:#{padInt d.getSeconds(), 2}:#{padInt d.getMilliseconds(), 3}"

padInt = (int, length) ->
  str = '' + int
  str = '0' + str while str.length < length
  str

# ---

[deep,shallow] = [yes,no]

newRowNode = -> $ rowNodePrototype.cloneNode deep
rowNodePrototype = $("""
<div class="row">
  <div class="summary">
    <div class="label"></div>
    <div class="body"></div>
    <div class="timestamp"></div>
  </div>
  <div class="meta-details"></div>
  <div class="details"></div>
</div>
""")[0]

# todo: factor out meta details

newMetaDetailsNode = -> $ metaDetailsNodePrototype.cloneNode deep
metaDetailsNodePrototype = $("""
<div class="meta-details">
  <div class="segment pid">
    <div class="label">Process id</div>
    <div class="value"></div>
  </div>
  <div class="segment argv">
    <div class="label">ARGV</div>
    <div class="value"></div>
  </div>
</div>
""")[0]

newSegmentNode = -> $ segmentNodePrototype.cloneNode deep
segmentNodePrototype = $("""
<div class="segment">
  <div class="label"></div>
  <div class="value"></div>
</div>
""")[0]

# ---

# All this handler code is less crap than it used to be but still crap

handlers = []

# not sure about the builder interface
class HandlerBuilder

  constructor: (name) ->
    @handler = {}
    @handler.name = name

  match: (fn) -> @handler.match = fn
  # todo: @handler.summaryRenderer?
  summary: (fn) -> @handler.summary = fn
  details: (fn) -> @handler.detailsRenderer = fn
  # todo: @handler.rowRenderer?
  row: (fn) -> @handler.row = fn
  when: (name, opts, fn) ->
    @handler.callback = { name, timeout: opts.timeout, callback: fn }

# ---

mprobe.handler = addHandler = (name, builder) ->
  context = new HandlerBuilder name
  builder.call context
  handlers.push context.handler

# ---

mprobe.handler 'SQL', ->

  @match (m) -> m.sql_start?

  @row (m) -> @data = @msg.body.sql_start

  @summary ->
    data = @row.data
    @addSegment 'query', data.query, color: 'sql'
    @addSegment 'params', JSON.stringify(data.params), color: 'json', label: 'params' if data.params?
    @addSegment 'duration', '...'

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state

    if firstTime
      @detailsNode.append mprobe.createSegment
        value: @data.query, color: 'sql'

      if @data.params?
        @detailsNode.append mprobe.createSegment
          label: 'params', value: JSON.stringify(@data.params), color: 'json'

    @detailsNode.toggle state
    @loadedRow?.toggleDetails()

  @when 'SQL end', timeout: 1000, (loadedRow) ->
    return no unless @data.id is loadedRow.data.id
    ms = mprobe.delta loadedRow.msg, @msg
    @summary.updateSegment 'duration', ms
    @loadedRow = loadedRow

mprobe.handler 'SQL end', ->

  @match (m) -> m.sql_end?

  @row ->
    @data = @msg.body.sql_end
    @hide()

  # only called when 'SQL' details toggled
  @details (state, firstTime) ->
    if firstTime
      @node.show()
      resultOrError = if @data.error? then 'error' else 'result'
      @detailsNode.append mprobe.createSegment
        class: resultOrError, label: resultOrError, value: JSON.stringify(@data[resultOrError]), color: 'json'

    @node.toggleClass 'focused', state
    @detailsNode.toggle state
    @node.toggle state

  @summary ->
    data = @row.data
    resultOrError = if data.error? then 'error' else 'result'
    @addSegment resultOrError, JSON.stringify(data[resultOrError]), color: 'json', label: resultOrError

# ---

mprobe.handler 'Request', ->

  @match (m) -> m.request_start?

  @row (m) -> @data = @msg.body.request_start

  @summary ->
    data = @row.data
    @addSegment 'method', data.method
    @addSegment 'url', data.url
    @addSegment 'duration', '...'

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @loadedRow?.toggleDetails()
    # todo: show request headers
    # todo: show cookies

  @when 'Request end', timeout: 1000, (loadedRow) ->
    return no unless @data.id is loadedRow.data.id
    ms = mprobe.delta loadedRow.msg, @msg
    @summary.updateSegment 'duration', ms
    @loadedRow = loadedRow

mprobe.handler 'Request end', ->

  @match (m) -> m.request_end?

  @row ->
    @data = @msg.body.request_end

  @summary ->
    data = @row.data
    @addSegment 'status', data.status

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state

# ---

mprobe.handler 'Templates Load', ->

  @match (m) -> m is 'templates_load'

  @row ->
    @data = @msg.body

  @summary ->
    @addSegment 'duration', '...'

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @loadedRow?.toggleDetails()

  @when 'Templates Loaded', timeout: 1000, (loadedRow) ->
    # return no unless @data is loadedRow.data
    ms = mprobe.delta loadedRow.msg, @msg
    @summary.updateSegment 'duration', ms
    @loadedRow = loadedRow

mprobe.handler 'Templates Loaded', ->

  @match (m) -> m is 'templates_loaded'

  @row ->
    @data = @msg.body
    @hide()

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @node.show if firstTime
    @node.toggle state

# ---

mprobe.handler 'Render', ->

  @match (m) -> m.template_render?

  @row ->
    @data = @msg.body.template_render

  @summary ->
    data = @row.data
    @addSegment 'name', data.name
    @addSegment 'error', ''
    @addSegment 'duration', '...'

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @loadedRow?.toggleDetails()

  @when 'Render end', timeout: 1000, (loadedRow) ->
    return no unless @data.id is loadedRow.data.id
    ms = mprobe.delta loadedRow.msg, @msg
    @summary.updateSegment 'duration', ms
    if loadedRow.data.error?
      @summary.updateSegment 'error', loadedRow.data.error

    @loadedRow = loadedRow

mprobe.handler 'Render end', ->

  @match (m) -> m.template_rendered?

  @row ->
    @data = @msg.body.template_rendered
    @hide()

  @details (state, firstTime) ->
    if firstTime
      if @data.error?
        @detailsNode.append mprobe.createSegment class: 'error', value: @data.error

    @detailsNode.toggle state
    @node.toggleClass 'focused', state
    @node.toggle state

# ---

mprobe.handler 'App Load', ->

  @match (m) -> m is 'app_load'

  @row ->
    @data = @msg.body

  @summary ->
    @addSegment 'duration', '...'

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @loadedRow?.toggleDetails()

  @when 'App Loaded', timeout: 1000, (loadedRow) ->
    ms = mprobe.delta loadedRow.msg, @msg
    @summary.updateSegment 'duration', ms
    @loadedRow = loadedRow

mprobe.handler 'App Loaded', ->

  @match (m) -> m is 'app_loaded'

  @row ->
    @data = @msg.body
    @hide()

  @details (state, firstTime) ->
    @node.toggleClass 'focused', state
    @node.show if firstTime
    @node.toggle state

# ---

mprobe.handler 'Probe', ->

  @match (m) -> yes

  @row -> @data = @msg.body

  @summary ->
    data = @row.data
    @addSegment 'data', JSON.stringify(data), color: 'json'

  @details (state, firstTime) ->
    if firstTime
      if (typeof @data is 'object') or (@data.length?)
        @detailsNode.append mprobe.createSegment value: mprobe.prettyPrintJson(JSON.stringify(@data)), color: 'json'
      else
        @detailsNode.append mprobe.createSegment value: JSON.stringify(@data), color: 'json'

    @node.toggleClass 'focused', state
    @node.find('.details').toggle state

# ---

# Handler helpers

# difference between creation times of two messages
mprobe.delta = (oldMsg, newMsg) ->
  ms = oldMsg.meta.timestamp - newMsg.meta.timestamp
  ms + 'ms'

mprobe.newLinesToBr = (str) ->
  str.replace(/\n/g, '<br>')

mprobe.synHighlight = prettyPrintOne

mprobe.prettyPrintJson = (jsonStr) ->
  Js2coffee.build "(#{jsonStr})"

mprobe.createSegment = (opts) ->
  segNode = newSegmentNode()

  segNode.addClass opts.class if opts.class?

  if opts.label?
    segNode.find('.label').text opts.label
  else
    segNode.find('.label').remove()

  value = mprobe.newLinesToBr(opts.value)
  value = mprobe.synHighlight(mprobe.newLinesToBr(value), opts.color) if opts.color?

  segNode.find('.value').html value

  segNode
