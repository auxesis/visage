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
        match = !!item.get('id').match(term)
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
    className: 'hostcollection',
    render: () ->
      that = this
      that.el.empty()
      that.collection.each((host) ->
        view = new DimensionView({model: host})
        that.el.grab(view.render()) if host.get('display')
      )
      if that.el.getChildren().length == 0
        message = new Element('li', {
          'html': 'No matches',
          'class': 'row',
        })
        that.el.grab(message)

      return that
  })

  #
  # Instantiate everything
  #
  hosts     = new HostCollection
  hostsView = new DimensionCollectionView({collection: hosts})
  hosts.fetch({
    success: (collection) ->
      list = hostsView.render().el
      $('hosts').grab(list)
  })
  hostSearch = new Element('input', {
    'type': 'text',
    'class': 'search',
    'autocomplete': 'off',
    'events': {
      'keyup': (event) ->
        term = event.target.value
        hosts.filter(term)

        list = hostsView.render().el
        $('hosts').grab(list)
    }
  })
  $('hosts').grab(hostSearch)



  metrics     = new MetricCollection
  metricsView = new DimensionCollectionView({collection: metrics})
  metrics.fetch({
    success: (collection) ->
      list = metricsView.render().el
      $('metrics').grab(list)
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
        console.log('hosts',   hosts.where({checked: true}))
        console.log('metrics', metrics.where({checked: true}))
    }
  })
  $('display').grab(button)
)
