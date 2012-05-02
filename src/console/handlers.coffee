# ---

mprobe.handler 'SQL', ->

  @match (m) -> m.sql_start?

  @init (m) ->
    @data = @msg.body.sql_start

  @renderSummary ->
    @addSummarySegment 'Query', @data.query, showLabel: no, color: 'sql', maxWidth: (if @data.params? then '40%' else '80%')
    @addSummarySegment 'Params', JSON.stringify(@data.params), color: 'json', maxWidth: '40%' if @data.params?
    @addSummarySegment 'Duration', '...', showLabel: no

  @toggleDetails (event) ->
    @endRow?.toggleDetails() if event?

  @renderDetails ->
    @addDetailSegment 'Query', mprobe.newLinesToBr(@data.query), showLabel: no, color: 'sql'
    @addDetailSegment 'Params', mprobe.prettyPrintJson(JSON.stringify(@data.params)), color: 'json' if @data.params?

  @when 'SQL end', timeout: 1000, (endRow) ->
    return no unless @data.id is endRow.data.id
    endRow.startRow = this; this.endRow = endRow

    ms = mprobe.delta endRow.msg, @msg
    @updateSummarySegment 'Duration', ms
    if @data.error?
      @addSummarySegment 'Error', JSON.stringify(endRow.data.error), color: 'json'
    else
      @addSummarySegment 'Rows', endRow.data.result.rowCount


mprobe.handler 'SQL end', ->

  @match (m) -> m.sql_end?

  @init ->
    @data = @msg.body.sql_end
    @hide()

  @renderSummary ->
    [label, field] = if @data.error? then ['Error','error'] else ['Result','result']
    @addSummarySegment label, JSON.stringify(@data[field]), color: 'json'

  @toggleDetails (event) ->
    @node.toggle()
    @startRow?.toggleDetails() if event?

  @renderDetails ->
    [label, field] = if @data.error? then ['Error','error'] else ['Result','result']
    @addDetailSegment label, mprobe.newLinesToBr(mprobe.prettyPrintJson(JSON.stringify(@data[field]))), color: 'json'

# ---

mprobe.handler 'Request', ->

  @match (m) -> m.request_start?

  @init (m) ->
    @data = @msg.body.request_start

  @renderSummary ->
    @addSummarySegment 'Method', @data.method, showLabel: no
    @addSummarySegment 'Url', @data.url, showLabel: no
    @addSummarySegment 'Duration', '...', showLabel: no

  @renderDetails ->
    @addDetailSegment 'Method', @data.method
    @addDetailSegment 'Url', @data.url
    @addDetailSegment 'Headers', mprobe.prettyPrintJson(JSON.stringify(@data.headers)), color: 'json'

  @toggleDetails (event) ->
    # if this row is being clicked, also show the endRow
    @endRow?.toggleDetails() if event?

  @when 'Request end', timeout: 10000, (endRow) ->
    return no unless @data.id is endRow.data.id
    endRow.startRow = this; this.endRow = endRow

    ms = mprobe.delta endRow.msg, @msg
    @updateSummarySegment 'Duration', ms

    @addSummarySegment 'Status', endRow.data.status


mprobe.handler 'Request end', ->

  @match (m) -> m.request_end?

  @init ->
    @data = @msg.body.request_end
    @hide()

  @renderSummary ->
    @addSummarySegment 'Status', @data.status

  @renderDetails ->
    # todo: show response headers

  @toggleDetails (event) ->
    @node.toggle()
    @detailsNode.hide()
    @startRow?.toggleDetails() if event?


# ---

mprobe.handler 'Templates Load', ->

  @match (m) -> m is 'templates_load'

  @renderSummary ->
    @addSummarySegment 'Duration', '...'

  # todo: show template names

  @toggleDetails (event) ->
    @detailsNode.hide()
    @endRow?.toggleDetails() if event?

  @when 'Templates Loaded', timeout: 1000, (endRow) ->
    this.endRow = endRow; endRow.startRow = this
    @updateSummarySegment 'Duration', mprobe.delta(endRow.msg, @msg)


mprobe.handler 'Templates Loaded', ->

  @match (m) -> m is 'templates_loaded'

  @init -> @hide()

  @toggleDetails (event) ->
    @node.toggle()
    @detailsNode.hide()
    @startRow?.toggleDetails() if event?

# ---

mprobe.handler 'Render', ->

  @match (m) -> m.template_render?

  @init ->
    @data = @msg.body.template_render

  @renderSummary ->
    @addSummarySegment 'Name', @data.name, showLabel: no
    @addSummarySegment 'Error', '', showLabel: no
    @addSummarySegment 'Duration', '...', showLabel: no

  @toggleDetails (event) ->
    @detailsNode.hide()
    @endRow?.toggleDetails() if event?

  @when 'Render end', timeout: 1000, (endRow) ->
    return no unless @data.id is endRow.data.id
    this.endRow = endRow; endRow.startRow = this
    @updateSummarySegment 'Duration', mprobe.delta(endRow.msg, @msg)

    if endRow.data.error?
      @summary.updateSegment 'Error', endRow.data.error

mprobe.handler 'Render end', ->

  @match (m) -> m.template_rendered?

  @init ->
    @data = @msg.body.template_rendered
    @hide()

  @renderDetails ->
    if @data.error?
      # todo: better formatting
      @addDetailSegment 'Error', @data.error

  @toggleDetails (event) ->
    @node.toggle()
    @detailsNode.hide()
    @startRow?.toggleDetails() if event?

# ---

mprobe.handler 'Debug', ->

  @match (m) -> m.debug?

  @init -> @data = @msg.body

  @renderSummary ->
    @addSummarySegment (@data.label or 'Data'), _.escape(@data.debug), color: 'json', showLabel: @data.label?

  @renderDetails ->
    @addDetailSegment (@data.label or 'Data'), _.escape(@data.debug).replace(), color: 'json'

# ---

mprobe.handler 'Probe', ->

  @match (m) -> yes

  @init -> @data = @msg.body

  @renderSummary ->
    @addSummarySegment 'Data', JSON.stringify(@data), color: 'json', showLabel: no

  @renderDetails ->
    if (typeof @data is 'object') or (@data.length?)
      @addDetailSegment 'Data', mprobe.newLinesToBr(mprobe.prettyPrintJson(JSON.stringify(@data))), color: 'json', showLabel: no
    else
      @addDetailSegment 'Data', JSON.stringify(@data), color: 'json', showLabel: no

