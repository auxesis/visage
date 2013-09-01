window.addEvent('domready', () ->

  Workspace = Backbone.Router.extend({
    routes: {
      'profile/new': 'profile',
      'profile/:id': 'profile'
    },
  });
  # FIXME(auxesis): use of global variable window - is this the best pattern?
  window.Application = new Workspace()

  Backbone.history.start({pushState: true})

  #
  # Instantiate everything
  #
  hostsContainer = $('hosts')
  hosts     = new HostCollection
  hostsView = new DimensionCollectionView({
    collection: hosts,
    container: hostsContainer
  })
  hosts.fetch({
    success: (collection) ->
      list = hostsView.render().el
      hostsContainer.grab(list)
  })

  metricsContainer = $('metrics')
  metrics     = new MetricCollection
  metricsView = new DimensionCollectionView({
    collection: metrics
    container:  metricsContainer
    linked:     hosts
  })

  # FIXME(auxesis): use of global variable window - is this the best pattern?
  window.graphsContainer = $('graphs')
  window.graphs   = new GraphCollection
  window.graphsView      = new GraphCollectionView({
    el:         window.graphsContainer
    collection: window.graphs
  })

  # If we're working with an existing profile, fetch the details and render
  # the graphs
  window.profile = new Profile()
  if not window.profile.isNew()
    window.profile.fetch({
      success: (model) ->
        model.get('graphs').each((attributes) ->
          graph = new Graph(attributes)
          graph.fetch({
            success: (model, response) ->
              # FIXME(auxesis): use of global variable window - is this the best pattern?
              window.graphs.add(graph)
              window.graphsView.render().el
          })
        )

        if model.get('timeframe')
          timeframesView.collection.each((timeframe) -> timeframe.set('selected', false))
          timeframesView.collection.add({
            label:    'As specified by profile',
            selected: true
          }, {at: 0})
          timeframesView.render()
    })

  button = new Element('input', {
    'type': 'button',
    'value': 'Add graphs',
    'class': 'button',
    'styles': {
      'font-size': '80%',
      'padding': '4px 8px',
    },
    'events': {
      'click': (event) ->
        hosts.for_api().each((host) ->
          metrics.for_api().each((metric) ->

            attributes = {
              host:   host
              plugin: metric
            }
            timeframe  = JSON.decode(Cookie.read('timeframe'))
            attributes = Object.merge(attributes, timeframe)

            graph = new Graph(attributes)
            graph.fetch({
              success: (model, response, options) ->
                # FIXME(auxesis): use of global variable window - is this the best pattern?
                # FIXME(auxesis): this displays graphs in the reverse order of how they're stored in the data structure
                graphs = JSON.parse(JSON.stringify(window.profile.get('graphs')))
                graphs.push(graph.attributes)
                window.profile.set('graphs', graphs)

                window.graphs.add(graph)
                window.graphsView.render().el
              error: (model, response, options) ->
                console.log('error', model, response, options)
            })
          )

          builder = $('builder')
          builder.tween('padding-top', 24).get('tween').chain(() ->
            builder.setStyle('border-top', '1px dotted #aaa')
          )


        )
    }
  })
  $('display').grab(button)


  timeframes = new TimeframeCollection
  timeframes.add([
    { label: 'last 1 hour',      start: -1,     unit: 'hours', 'default': true }
    { label: 'last 2 hours',     start: -2,     unit: 'hours' }
    { label: 'last 6 hours',     start: -6,     unit: 'hours' }
    { label: 'last 12 hours',    start: -12,    unit: 'hours' }
    { label: 'last 24 hours',    start: -24,    unit: 'hours' }
    { label: 'last 3 days',      start: -72,    unit: 'hours' }
    { label: 'last 7 days',      start: -168,   unit: 'hours' }
    { label: 'last 2 weeks',     start: -336,   unit: 'hours' }
    { label: 'last 1 month',     start: -774,   unit: 'hours' }
    { label: 'last 3 months',    start: -2322,  unit: 'hours' }
    { label: 'last 6 months',    start: -4368,  unit: 'hours' }
    { label: 'last 1 year',      start: -8760,  unit: 'hours' }
    { label: 'last 2 years',     start: -17520, unit: 'hours' }
    { label: 'current month',    start: 0,  finish: 1,  unit: 'months' }
    { label: 'previous month',   start: -1, finish: 0,  unit: 'months' }
    { label: 'two months ago',   start: -2, finish: -1, unit: 'months' }
    { label: 'three months ago', start: -3, finish: -2, unit: 'months' }
  ])

  if !Cookie.read('timeframe')
    attributes = timeframes.find((model) -> model.get('default')).toTimeAttributes()
    Cookie.write('timeframe', JSON.encode(attributes))

  timeframesView = new TimeframeCollectionView({
    collection: timeframes,
    el:         $('timeframes')
  })
  timeframesView.render()
)
