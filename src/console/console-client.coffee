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
handlers = []

# proceed with MindWizardry
processIncomingMessage = (msg) ->
  # create row and add it to the store
  row = new Row msg
  rows[row.id] = row

  for handler in handlers
    if handler.match msg.body
      # link the row to the hanlder that will process it
      row.handler = handler

      handler.init.call(row) if handler.init?
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

# public interface for creating handers
mprobe.handler = (name, builder) ->
  context = new HandlerBuilder name
  builder.call context
  handlers.push context.handler

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

# ---

# builder api
class HandlerBuilder

  constructor: (name) ->
    @handler = {}
    @handler.name = name

  match: (fn) -> @handler.match = fn
  init: (fn)  -> @handler.init = fn

  summary: (fn) -> @handler.summary = fn
  details: (fn) -> @handler.detailsRenderer = fn

  when: (name, opts, fn) ->
    @handler.callback = { name, timeout: opts.timeout, callback: fn }

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
