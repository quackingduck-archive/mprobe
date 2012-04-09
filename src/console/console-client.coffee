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

  if      $(event.target).closest('.label')     then rows[id].toggleDetails(event)
  else if $(event.target).closest('.summary')   then rows[id].toggleDetails(event)
  # todo: make this work again
  # else if $(event.target).closest('.timestamp') then rows[id].toggleMetaDetails()

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
      handler.renderSummary.call(row) if handler.renderSummary?

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

# ---

# builder api
class HandlerBuilder

  constructor: (name) ->
    @handler = {}
    @handler.name = name

  match: (fn) -> @handler.match = fn
  init: (fn)  -> @handler.init = fn

  renderSummary: (fn) -> @handler.renderSummary = fn
  renderDetails: (fn) -> @handler.renderDetails = fn
  toggleDetails: (fn) -> @handler.toggleDetails = fn

  when: (name, opts, fn) ->
    @handler.callback = { name, timeout: opts.timeout, callback: fn }

# ---

class Row

  # much of this feels too fancy

  constructor: (@msg) ->
    @id = msg.meta.timestamp + '-' + Math.random().toString().split('.')[1]
    @node = newRowNode()
    @detailsNode = @node.find('.details')
    @summaryBodyNode = @node.find('.summary .body')

  render: ->
    @node.data 'id', @id
    @node.addClass @computeClass()

    @node.find('.meta-details').toggle off
    @node.find('.details').toggle off

    @node.find('.timestamp').text formatTime @msg.meta.timestamp
    @node.find('.summary > .label').text @computeLabel()

  addSummarySegment: (label, value, opts) ->
    @summaryBodyNode.append mprobe.createSegmentNode label, value, opts

  updateSummarySegment: (label, value) ->
    @summaryBodyNode.find(".segment[data-label='#{label}']").text value

  addDetailSegment: (label, value, opts) ->
    @detailsNode.append mprobe.createSegmentNode label, value, opts

  computeLabel: ->
    @handler?.name or "probe"

  computeClass: ->
    @explicitlySetClass or @computeLabel().replace(/[ ]/g,'-').toLowerCase()

  toggleDetails: (event) ->
    unless (@renderedDetails ?= no)
      @handler.renderDetails.call(@) if @handler.renderDetails?
      @renderedDetails = yes

    @node.toggleClass 'focused'
    @detailsNode.toggle()
    @handler.toggleDetails.call(this,event) if @handler.toggleDetails?


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

# ---

formatTime = (ms) ->
  d = new Date ms
  "'#{padInt d.getMinutes(), 2}:#{padInt d.getSeconds(), 2}:#{padInt d.getMilliseconds(), 3}"

padInt = (int, length) ->
  str = '' + int
  str = '0' + str while str.length < length
  str

# ---

mprobe.createSegmentNode = (label, value, opts = {}) ->
  segNode = newSegmentNode()

  # todo: deprecate
  segNode.addClass opts.class or label.replace(/[ ]/g,'-').toLowerCase()

  segNode.css 'max-width', opts.maxWidth if opts.maxWidth?

  segNode.data 'label', label

  segNode.find('.label').text label
  segNode.find('.label').hide() if opts.showLabel is no

  value = mprobe.synHighlight(value, opts.color) if opts.color?
  segNode.find('.value').html value

  segNode

mprobe.newLinesToBr = (str) ->
  str.replace(/\n/g, '<br>')

mprobe.synHighlight = prettyPrintOne

mprobe.prettyPrintJson = (jsonStr) ->
  Js2coffee.build "(#{jsonStr})"

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
