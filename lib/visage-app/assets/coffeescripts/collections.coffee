#
# Collections
#
HostCollection = Backbone.Collection.extend({
  url: '/data',
  model: Host,
  parse: (response) ->
    attrs = response.hosts.map((host) ->
      { id: host }
    )
  # FIXME: Refactor into common class
  filter: (term) ->
    this.each((item) ->
      try
        match = !!item.get('id').match(term)
      catch error
        throw error unless error.type == 'malformed_regexp'

      item.set('display', match)
    )
  # FIXME: Refactor into common class
  selected: () ->
    this.models.filter((model) -> model.get('checked') == true)
})

MetricCollection = Backbone.Collection.extend({
  url: () ->
    '/data/' + this.getConditions().join(',')

  model: Metric,
  parse: (response) ->
    attrs = response.metrics.map((metric) ->
      { id: metric }
    )
    _.sortBy(attrs, (attr) -> attr.id)

  # FIXME: Refactor into common class
  filter: (term) ->
    this.each((item) ->
      try
        match = !!item.get('id').match(term)
      catch error
        throw error unless error.type == 'malformed_regexp'

      item.set('display', match)
    )

  # FIXME: Refactor into common class
  selected: () ->
    this.models.filter((model) -> model.get('checked') == true)

  initialize: () ->
    this.conditions = []
  setConditions: (conditions) ->
    this.conditions = conditions
  getConditions: () ->
    this.conditions
})

GraphCollection = Backbone.Collection.extend({
  model: Graph
})

TimeframeCollection = Backbone.Collection.extend({
  model: Timeframe
})

