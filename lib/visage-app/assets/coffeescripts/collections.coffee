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
        if not error instanceof SyntaxError
          throw error

      item.set('display', match)
    )
  # FIXME: Refactor into common class
  selected: () ->
    this.models.filter((model) -> model.get('checked') == true)
  for_api: () ->
    this.selected().map((host) -> host.get('id')).unique()
})

MetricCollection = Backbone.Collection.extend({
  url: () ->
    '/data/' + this.getConditions().join(',')

  model: Metric,
  parse: (response) ->
    # TODO(auxesis): add support for nesting instances under plugins
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
        if not error instanceof SyntaxError
          throw error

      item.set('display', match)
    )

  # FIXME: Refactor into common class
  selected: () ->
    this.models.filter((model) -> model.get('checked') == true)
  for_api: () ->
    selected = {}
    selected_metrics = []

    this.selected().each((metric) ->
      id = metric.get('id')
      [ plugin, instance ] = id.split('/')
      selected[plugin] ||= []
      selected[plugin].include(instance)
    )
    Object.each(selected, (item, key, object) ->
      selected_metrics.include("#{key}/#{item.join(',')}")
    )

    selected_metrics

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

