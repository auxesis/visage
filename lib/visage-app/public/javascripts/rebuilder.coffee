window.addEvent('domready', () ->

  BuildDimensionSelector = (name, element, dimensions) ->
    container = $(element)
    dimensions.each((dimension) ->
      id       = dimension.id

      li       = new Element('li', {
        'class': "#{name} row"
        'events': {
          'click': (event) ->
            checkbox = event.target.getElement('input.checkbox')
            checkbox.checked = !checkbox.checked if checkbox
        }
      })
      checkbox = new Element('input', {
        'type':  'checkbox',
        'name':  id,
        'id':    id,
        'class': "#{name} checkbox",
      })
      label    = new Element('label', {
        'for': id,
        'html': id,
        'class': "#{name} label",
      })
      li.grab(checkbox)
      li.grab(label)
      container.grab(li)
    )

  Host = Backbone.Model.extend({
    hostname: () ->
      this.get('fqdn').split('.')[0]
  });

  Hosts = Backbone.Collection.extend({
    url: '/data',
    model: Host,
    parse: (response) ->
      attrs = response.hosts.map((host) ->
        { id: host }
      )
  });

  hosts = new Hosts;
  hosts.on('reset', (hosts) ->
    BuildDimensionSelector('host', $('hosts'), hosts)
  )
  hosts.fetch();

  Metric = Backbone.Model.extend({
    plugin: () ->
      this.get('id').split('/')[0]
    instance: () ->
      this.get('id').split('/')[1]
  });

  Metrics = Backbone.Collection.extend({
    url: '/data/*',
    model: Metric,
    parse: (response) ->
      attrs = response.metrics.map((metric) ->
        { id: metric }
      )

      _.sortBy(attrs, (attr) -> attr.id)
  });


  metrics = new Metrics;
  metrics.on('reset', (metrics) ->
    BuildDimensionSelector('metric', $('metrics'), metrics)
  )

  metrics.fetch();
)
