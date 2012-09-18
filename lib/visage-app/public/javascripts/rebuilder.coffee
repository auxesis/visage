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

      return obj
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

  GraphView = Backbone.View.extend({
    tagName: 'li',
    className: 'graph',
    title: () ->
      that    = this
      plugin  = that.model.get('plugin')
      host    = that.model.get('host')

      if that.options.title
        that.options.title
      else
        plugin = plugin.split('-')[1].replace(/(-|_)/, ' ') if plugin.match(/^curl_json/)
        [ plugin, 'on', host ].join(' ')

    seriesMinMax: () ->
      that    = this
      series  = that.model.get('series')

      endpoints = series.map((set) ->
        values = set.data.map((point) ->
          point[1]
        )

        min = values.min()
        max = values.max()
        [ min, max ]
      )

      min = endpoints.map((min, max) -> min).min()
      max = endpoints.map((min, max) -> max).max()

      [ min, max ]

    render: () ->
      that    = this
      element = that.el
      series  = that.model.get('series')
      title   = that.title() # FIXME: Refactor to make the title an editable field
      [ min, max ] = that.seriesMinMax()

      element.setStyle('height', 0)
      that.chart = new Highcharts.Chart({
        series: series,
        chart: {
          renderTo:     element,
          type:         'line',
          marginRight:  0,
          marginBottom: 60,
          zoomType:     'xy',

          resetZoomButton: {
            theme: {
              fill: 'white',
              stroke: '#020508',
              r: 0,
              states: {
                hover: {
                  fill: '#020508',
                  style: {
                    color: 'white'
                  }
                }
              }
            }
          },


          width:        873,
          height:       350,
          plotBorderWidth: 1,
          plotBorderColor: '#020508',
          events: {}
        },
        title: {
          text: title
          style: {
            'fontSize':    '18px',
            'fontWeight':  'bold',
            'color':       '#333333',
            'font-family': 'Bitstream Vera Sans, Helvetica Neue, sans-serif',
          }
        },
        colors: [
          '#1F78B4',
          '#33A02C',
          '#E31A1C',
          '#FF7F00',
          '#6A3D9A',
          '#A6CEE3',
          '#B2DF8A',
          '#FB9A99',
          '#FDBF6F',
          '#CAB2D6',
          '#FFFF99',
        ],

        xAxis: {
          lineWidth: 0,
          minPadding: 0.012,
          maxPadding: 0.012,
          tickLength: 5,
          tickColor: "#020508",
          startOnTick: false,
          endOnTick: false,
          gridLineWidth: 0,

          tickPixelInterval: 150,

          labels: {
            style: {
              color: '#000',
            },
          },

          title: {
            text: null
          },
          type: 'datetime',
          dateTimeLabelFormats: {
            second: '%H:%M:%S',
            minute: '%H:%M',
            hour: '%H:%M',
            day: '%d/%m',
            week: '%d/%m',
            month: '%m/%Y',
            year: '%Y'
          }
        },
        yAxis: {
          lineWidth: 0,
          minPadding: 0.05,
          maxPadding: 0.05,
          tickWidth: 1,
          tickColor: '#020508',
          startOnTick: false,
          endOnTick: false,
          gridLineWidth: 0,

          title: {
            text: null
          },
          labels: {
            style: {
              color: '#000',
            },
            formatter: () ->
              precision = 1
              value     = formatValue(this.value, {
                              'precision': precision,
                              'min':       min,
                              'max':       max
                          });
          },
        },
        plotOptions: {
          series: {
            shadow: false,
            lineWidth: 1,
            marker: {
              enabled: false,
              states: {
                hover: {
                  enabled: true,
                  radius: 4,
                },
              },
            },
            states: {
              hover: {
                enabled: true,
                lineWidth: 1,
              },
            }
          }
        },
        tooltip: {
          formatter: () ->
            tip =  '<strong>'
            tip += formatSeriesLabel(this.series.name).trim()
            tip += '</strong>' + ' -> '
            tip += '<span style="font-family: monospace; font-size: 14px;">'
            tip += formatValue(this.y, { 'precision': 2, 'min': min, 'max': max })
            tip += '<span style="font-size: 9px; color: #777">'
            tip += ' (' + this.y + ')'
            tip += '</span>'
            tip += '</span>'
            tip += '<br/>'
            tip += '<span style="font-family: monospace">'
            tip += formatDate(this.x)
            tip += '</span>'

            return tip
        },
        legend: {
          layout: 'horizontal',
          align: 'center',
          verticalAlign: 'top',
          y: 320,
          borderWidth: 0,
          floating: true,
          labelFormatter: () ->
            formatSeriesLabel(this.name)
          itemStyle: {
            cursor: 'pointer',
            color:  '#1a1a1a'
          },
          itemHoverStyle: {
            color:  '#111'
          }
        },
        credits: {
          enabled: false
        }
      })

      destroy = new Element('div', {
        'class': 'action destroy'
        'styles': {
          opacity: 0
        }
        'events': {
          'click': (event) ->
            that.el.fade('out').get('tween').chain(() ->
              that.el.tween('height', '0').get('tween').chain(() ->
                that.chart.destroy()
                that.el.destroy()
                that.model.collection.remove(that.model)
                that.model.destroy()
              )
            )
        }
      })
      # http://raphaeljs.com/icons/
      destroyPaper = Raphael(destroy, 26, 26);
      destroyPaper.path("M24.778,21.419 19.276,15.917 24.777,10.415 21.949,7.585 16.447,13.087 10.945,7.585 8.117,10.415 13.618,15.917 8.116,21.419 10.946,24.248 16.447,18.746 21.948,24.248z")

      move = new Element('div', {
        'class': 'action move'
        'styles': {
          opacity: 0
          cursor: 'move'
        }
      })
      movePaper = Raphael(move, 26, 26);
      movePaper.path("M4.082,8.083v2.999h24.835V8.083H4.082zM4.082,24.306h22.835v-2.999H4.082V20.306zM4.082,17.694h22.835v-2.999H4.082V13.694z")

      # Insert icons.
      element.grab(move,  'top')
      element.grab(destroy, 'top')

      # Roll graph out.
      element.tween('height', 376)

      # Hide/show the icons based on mouse events.
      element.addEvent('mouseenter', () -> move.tween('opacity', 1))
      element.addEvent('mouseleave', () -> move.tween('opacity', 0))
      element.addEvent('mouseenter', () -> destroy.tween('opacity', 1))
      element.addEvent('mouseleave', () -> destroy.tween('opacity', 0))

      return element
  })

  GraphCollectionView = Backbone.View.extend({
    tagName: 'div',
    className: 'graph',
    initialize: () ->
      that     = this
      element  = that.el
      that.sortable = new Sortables(element, {
        handle:  'div.action.move'
        opacity: 0.3
        clone:   true
        revert:  { duration: 500, transition: 'back:out' }
      })

    render: () ->
      that = this
      that.collection.each((model) ->
        if not model.get('rendered')
          view  = new GraphView({model: model})
          graph = view.render()
          that.el.grab(graph)
          model.set('rendered', true) # So the graph isn't re-rendered every time "show" is clicked
          that.sortable.addItems(view.el)
      )
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
  graphsView      = new GraphCollectionView({
    el:         graphsContainer
    collection: graphs
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
        selected_plugins = metrics.selected().map((metric) -> metric.get('id').split('/')[0]).unique()
        selected_hosts   = hosts.selected().map((host) -> host.get('id')).unique()

        selected_hosts.each((host) ->
          selected_plugins.each((plugin) ->

            attributes = {
              host:    host
              plugin:  plugin
            }
            graph = new Graph(attributes)
            graph.fetch({
              success: (model, response) ->
                graphs.add(graph)
                graphsView.render().el
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
)
