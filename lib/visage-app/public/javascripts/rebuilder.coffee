window.addEvent('domready', () ->

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
    filter: (term) ->
      this.each((item) ->
        try
          match = !!item.get('id').match(term)
        catch error
          throw error unless error.type == 'malformed_regexp'

        item.set('display', match)
      )
  })

  MetricCollection = Backbone.Collection.extend({
    url: '/data/*',
    model: Metric,
    parse: (response) ->
      attrs = response.metrics.map((metric) ->
        { id: metric }
      )
      _.sortBy(attrs, (attr) -> attr.id)
    filter: (term) ->
      this.each((item) ->
        match = !!item.get('id').match(term)
        item.set('display', match)
      )
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
      search = new Element('input', {
        'type': 'text',
        'class': 'search',
        'autocomplete': 'off',
        'events': {
          'keyup': (event) ->
            term = event.target.value
            that.collection.filter(term)

            list = that.render().el
            container.grab(list)
        }
      })
      container.grab(search)

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
        console.log('hosts',   hosts, hosts.where({checked: true}))
        console.log('metrics', metrics, metrics.where({checked: true}))
    }
  })
  $('display').grab(button)
)
