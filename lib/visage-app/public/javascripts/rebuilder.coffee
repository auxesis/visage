window.addEvent('domready', () ->

  # Built roughly following pattern detailed here:
  #
  #   http://weblog.bocoup.com/backbone-live-collections/

  #
  # Models
  #
  Dimension = Backbone.Model.extend({
    defaults: {
      checked: false,
      display: true,
    },
  })

  Host   = Dimension.extend({})
  Metric = Dimension.extend({})
  Graph  = Backbone.Model.extend({
    url: () ->
      host   = this.get('host')
      plugin = this.get('plugin')
      start  = this.get('start')
      finish = this.get('finish')
      query  = {}
      query.start  = this.get('start')  if this.get('start')
      query.finish = this.get('finish') if this.get('finish')
      query = if query.length > 0 then '?' + Object.toQueryString(query) else ''

      "/data/#{host}/#{plugin}#{query}"
    parse: (response) ->
      host   = this.get('host')
      plugin = this.get('plugin')
      data   = response
      that   = this

      obj = {}
      obj.data   = data
      obj.series = []

      Object.each(data[host][plugin], (instance, instanceName) ->
        Object.each(instance, (metric, metricName) ->
          start    = metric.start
          finish   = metric.finish
          interval = (finish - start) / metric.data.length

          data = metric.data.map((value, index) ->
            x = (start + index * interval) * 1000
            y = value
            [ x, y ]
          )

          set = {
            name:         [ host, plugin, instanceName, metricName ]
            data:         data,
            percentile95: metric.percentile_95
          }

          obj.series.push(set)
        )
      )

      obj.series = obj.series.sort((a,b) ->
        return -1 if a.name[2] < b.name[2]
        return 1  if a.name[2] > b.name[2]
        return 0
      )

      obj
  })


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
    url: '/data/*',
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
  })



  GraphCollection = Backbone.Collection.extend({
    model: Graph
  })

  #
  # Views
  #
  DimensionView = Backbone.View.extend({
    tagName: 'li',
    className: 'row',
    render: () ->
      that = this
      id = name = this.model.id
      checkbox = new Element('input', {
        'type':  'checkbox',
        'id':    id,
        'class': "#{name} checkbox",
        'checked': this.model.get('checked'),
        'events': {
          'change': (event) ->
            that.model.set('checked', !that.model.get('checked'))
        }
      })
      label    = new Element('label', {
        'for': id,
        'html': id,
        'class': "#{name} label",
      })

      $(this.el).grab(checkbox)
      $(this.el).grab(label)
      $(this.el).addEvent('click', (event) ->
        if event.target.tagName.toLowerCase() == 'li'
          checkbox = event.target.getElement('input.checkbox')
          checkbox.checked = !checkbox.checked if checkbox
          that.model.set('checked', !that.model.get('checked'))
      )
  })

  DimensionCollectionView = Backbone.View.extend({
    tagName: 'ul',
    className: 'dimensioncollection',
    initialize: () ->
      that = this
      container = $(that.options.container)

      # FIXME: Refactor into dedicated class
      # http://stackoverflow.com/questions/6258521/clear-icon-inside-input-text
      icon = new Element('div', {
        'class': 'clear'
        'events': {
          'click': (event) ->
            term = ''
            input = event.target.getParent('div.dimension').getElement('input.search')
            input.set('value', term)
            that.collection.filter(term)

            list = that.render().el
            container.grab(list)

            icon = event.target.getParent('div.dimension').getElement('div.clear')
            icon.setStyle('display', 'none')
        }
      })
      # http://raphaeljs.com/icons/
      paper = Raphael(icon, 26, 26);
      paper.path("M24.778,21.419 19.276,15.917 24.777,10.415 21.949,7.585 16.447,13.087 10.945,7.585 8.117,10.415 13.618,15.917 8.116,21.419 10.946,24.248 16.447,18.746 21.948,24.248z").attr({fill: "#aaa", stroke: "none"});

      search = new Element('input', {
        'type': 'text',
        'class': 'search',
        'autocomplete': 'off',
        'events': {
          'keyup': (event) ->
            input = event.target
            term  = input.value

            # Filter the dimension based on search term
            that.collection.filter(term)

            list = that.render().el
            container.grab(list)

            # Display button to clear field
            if term.length > 0
              icon.setStyle('display', 'inline')
            else
              icon.setStyle('display', 'none')
        }
      })
      container.grab(search)
      container.grab(icon)

    render: () ->
      that = this
      that.el.empty()
      that.collection.each((model) ->
        view = new DimensionView({model: model})
        that.el.grab(view.render()) if model.get('display')
      )
      number_of_results = that.el.getChildren().length

      if number_of_results == 0
        message = new Element('li', {
          'html': 'No matches',
          'class': 'row',
        })
        that.el.grab(message)
      else
        selectAll = new Element('li', {
          'html': '&uarr; toggle all',
          'class': 'row toggle',
          'events': {
            'click': (event) ->
              checkboxes = that.el.getElements('input.checkbox')
              checkboxes.each((element) ->
                element.fireEvent('change')
                element.setProperty('checked', !element.getProperty('checked'))
              )
          }
        })
        that.el.grab(selectAll)

      return that
  })

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
    collection: metrics,
    container:  metricsContainer
  })
  metrics.fetch({
    success: (collection) ->
      list = metricsView.render().el
      metricsContainer.grab(list)
  })

  graphsContainer = $('graphs')
  graphs          = new GraphCollection
#  graphsView      = new GraphCollectionView({
#    collection: graphs
#    container:  graphsContainer
#  })
#  graphs.fetch({
#    success: (collection) ->
#      list = graphsView.render().el
#      graphsContainer.grab(list)
#  })

  #
  # Debug
  #
  button = new Element('input', {
    'type': 'button',
    'value': 'Show graphs',
    'class': 'button',
    'styles': {
      'font-size': '80%',
      'padding': '4px 8px',
    },
    'events': {
      'click': (event) ->
        selected_plugins = metrics.selected().map((metric) -> metric.get('id').split('/')[0]).unique()
        selected_hosts   = hosts.selected().map((host) -> host.get('id')).unique()

        selected_hosts.each((host) ->
          selected_plugins.each((plugin) ->

            attributes = {
              host:    host
              plugin:  plugin
            }
            graph = new Graph(attributes)
            graph.fetch()
            console.log(graph.attributes)

          )
        )
    }
  })
  $('display').grab(button)
)
