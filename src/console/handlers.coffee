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
