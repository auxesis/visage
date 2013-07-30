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
      'title': "#{name}",
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
  tagName:   'div'
  className: 'graph'
  views:     []
  initialize: () ->
    that     = this
    element  = that.el
    that.sortable = new Sortables(element, {
      handle:  'div.action.move'
      opacity: 0.3
      clone:   true
      revert:  { duration: 500, transition: 'back:out' }
    })

    # Toggler for sharing a link to the graph profile
    shareToggler = $('share-toggler')
    icon = new Element('div', {
      class: 'icon',
    })
    paper = Raphael(icon, 32, 32);
    paper.path("M16.45,18.085l-2.47,2.471c0.054,1.023-0.297,2.062-1.078,2.846c-1.465,1.459-3.837,1.459-5.302-0.002c-1.461-1.465-1.46-3.836-0.001-5.301c0.783-0.781,1.824-1.131,2.847-1.078l2.469-2.469c-2.463-1.057-5.425-0.586-7.438,1.426c-2.634,2.637-2.636,6.907,0,9.545c2.638,2.637,6.909,2.635,9.545,0l0.001,0.002C17.033,23.511,17.506,20.548,16.45,18.085zM14.552,12.915l2.467-2.469c-0.053-1.023,0.297-2.062,1.078-2.848C19.564,6.139,21.934,6.137,23.4,7.6c1.462,1.465,1.462,3.837,0,5.301c-0.783,0.783-1.822,1.132-2.846,1.079l-2.469,2.468c2.463,1.057,5.424,0.584,7.438-1.424c2.634-2.639,2.633-6.91,0-9.546c-2.639-2.636-6.91-2.637-9.545-0.001C13.967,7.489,13.495,10.451,14.552,12.915zM18.152,10.727l-7.424,7.426c-0.585,0.584-0.587,1.535,0,2.121c0.585,0.584,1.536,0.584,2.121-0.002l7.425-7.424c0.584-0.586,0.584-1.535,0-2.121C19.687,10.141,18.736,10.142,18.152,10.727z")

    modal = new LightFace.Request({
        width:     600,
        draggable: true,
        title:     'Share profile',
        content:   "<img src='/images/loader.gif'/>",
        request: {
          method: 'get'
        },
        buttons: [
            { title: "Close", color: 'blue', event: () -> this.close() }
        ],
        resetOnScroll: true
    });

    shareToggler.grab(icon, 'top')
    shareToggler.addEvent('click', () ->
      modal.open()

      current = Backbone.history.fragment.toString()

      # If we're saving a new profile (/profiles/new):
      #
      #  - Collect up all the graphs
      #  - Construct a new profile
      #  - Save the profile
      #  - Navigate to the permalink
      #  - Pop up a share dialog (to provide more customisation)
      #
      # If we're on an existing profile:
      #
      #  - Pop up a share dialog (to provide more customisation)
      #
      if current.test(/new$/)
        graphAttributes = graphs.toJSON().map((attrs) ->
          Object.subset(attrs , ['host', 'plugin', 'start', 'finish'])
        )

        profile = new Profile({
          graphs:    graphAttributes
          anonymous: true
          timeframe: true
        })

        profile.save({}, {
          success: (profile, response, options) ->
            Application.navigate("profiles/#{profile.id}", {trigger: true})
            modal.load("/profiles/share/#{profile.id}", "Share profile")

          error: (model, xhr, options) ->
            console.log(model, xhr, options)
        })
      else
        id = current.split('/')[1]
        modal.load("/profiles/share/#{id}", "Share profile")

        # modal.
    )

  render: () ->
    that = this
    that.collection.each((model) ->
      if not model.get('rendered')
        view  = new GraphView({model: model})
        that.views.include(view)
        graph = view.render()
        that.el.grab(graph)
        model.set('rendered', true) # So the graph isn't re-rendered every time "show" is clicked
        that.sortable.addItems(view.el)
    )
    return that
})

TimeframeView = Backbone.View.extend({
  tagName:   'li',
  className: 'timeframe',
  selected:  false,
  render: () ->
    that = this
    that.el.set('html', this.model.get('label'))
    that.el.addClass('selected') if that.model.get('selected') # for the timeframe in the cookie
    that.el.addEvent('click', () ->
      label = $('timeframe-label')
      label.set('html', that.model.get('label'))

      $('timeframes').fade('out')
      that.el.getParent('ul').getElements('li').each((el) ->
        el.removeClass('selected')
      )
      that.el.toggleClass('selected')

      attrs = that.model.toTimeAttributes()
      Cookie.write('timeframe', JSON.encode(attrs)) # So new graphs have the timeframe set

      graphs.models.each((graph) ->
        graph.set(attrs)
        graph.fetch(
          success: (model, response) ->
            graphsView.views.each((view) ->
              view.model.get('series').each((series, index) ->
                view.chart.series[index].setData(series.data, false)
              )
              view.chart.redraw()
            )
        )
      )

    )

    return that
})

TimeframeCollectionView = Backbone.View.extend({
  tagName: 'ul',
  className: 'timeframe',
  initialize: () ->
    that = this
    icon = new Element('div', {
      class: 'icon',
    })
    paper = Raphael(icon, 32, 32);
    paper.path("M10.666,18.292c0.275,0.479,0.889,0.644,1.365,0.367l3.305-1.677C15.39,16.99,15.444,17,15.501,17c0.828,0,1.5-0.671,1.5-1.5l-0.5-7.876c0-0.552-0.448-1-1-1c-0.552,0-1,0.448-1,1l-0.466,7.343l-3.004,1.96C10.553,17.204,10.389,17.816,10.666,18.292zM12.062,9.545c0.479-0.276,0.642-0.888,0.366-1.366c-0.276-0.478-0.888-0.642-1.366-0.366s-0.642,0.888-0.366,1.366C10.973,9.658,11.584,9.822,12.062,9.545zM8.179,18.572c-0.478,0.277-0.642,0.889-0.365,1.367c0.275,0.479,0.889,0.641,1.365,0.365c0.479-0.275,0.643-0.888,0.367-1.367C9.27,18.461,8.658,18.297,8.179,18.572zM9.18,10.696c-0.479-0.276-1.09-0.112-1.366,0.366s-0.111,1.09,0.365,1.366c0.479,0.276,1.09,0.113,1.367-0.366C9.821,11.584,9.657,10.973,9.18,10.696zM6.624,15.5c0,0.553,0.449,1,1,1c0.552,0,1-0.447,1.001-1c-0.001-0.552-0.448-0.999-1.001-1C7.071,14.5,6.624,14.948,6.624,15.5zM14.501,23.377c0,0.553,0.448,1,1,1c0.552,0,1-0.447,1-1s-0.448-1-1-1C14.949,22.377,14.501,22.824,14.501,23.377zM10.696,21.822c-0.275,0.479-0.111,1.09,0.366,1.365c0.478,0.276,1.091,0.11,1.365-0.365c0.277-0.479,0.113-1.09-0.365-1.367C11.584,21.18,10.973,21.344,10.696,21.822zM21.822,10.696c-0.479,0.278-0.643,0.89-0.366,1.367s0.888,0.642,1.366,0.365c0.478-0.275,0.643-0.888,0.365-1.366C22.913,10.584,22.298,10.42,21.822,10.696zM21.456,18.938c-0.274,0.479-0.112,1.092,0.367,1.367c0.477,0.274,1.089,0.112,1.364-0.365c0.276-0.479,0.112-1.092-0.364-1.367C22.343,18.297,21.73,18.461,21.456,18.938zM24.378,15.5c0-0.551-0.448-1-1-1c-0.554,0.002-1.001,0.45-1.001,1c0.001,0.552,0.448,1,1.001,1C23.93,16.5,24.378,16.053,24.378,15.5zM18.573,22.822c0.274,0.477,0.888,0.643,1.366,0.365c0.478-0.275,0.642-0.89,0.365-1.365c-0.277-0.479-0.888-0.643-1.365-0.367C18.46,21.732,18.296,22.344,18.573,22.822zM18.939,9.546c0.477,0.276,1.088,0.112,1.365-0.366c0.276-0.478,0.113-1.091-0.367-1.367c-0.477-0.276-1.09-0.111-1.364,0.366C18.298,8.659,18.462,9.27,18.939,9.546zM28.703,14.364C28.074,7.072,21.654,1.67,14.364,2.295c-3.254,0.281-6.118,1.726-8.25,3.877L4.341,4.681l-1.309,7.364l7.031-2.548L8.427,8.12c1.627-1.567,3.767-2.621,6.194-2.833c5.64-0.477,10.595,3.694,11.089,9.335c0.477,5.64-3.693,10.595-9.333,11.09c-5.643,0.476-10.599-3.694-11.092-9.333c-0.102-1.204,0.019-2.373,0.31-3.478l-3.27,1.186c-0.089,0.832-0.106,1.684-0.031,2.55c0.629,7.29,7.048,12.691,14.341,12.066C23.926,28.074,29.328,21.655,28.703,14.364z")

    toggler = $('timeframe-toggler')
    toggler.grab(icon, 'top')
    toggler.addEvent('click', () ->
      timeframesView.el.fade('toggle')
    )

    timeframe = JSON.decode(Cookie.read('timeframe'))
    if timeframe and timeframe.label
      label = $('timeframe-label')
      label.set('html', timeframe.label)

  default_timeframe: () ->
    that = this
    that.collection.find((model) -> model.get('default'))

  render: () ->
    timeframe = JSON.decode(Cookie.read('timeframe'))

    that = this
    that.el.empty()

    that.collection.each((model) ->

      if model == that.default_timeframe()
        model.set('selected', true)
        label = $('timeframe-label')
        label.set('html', timeframe.label)

      # for the timeframe in the cookie
      if timeframe and timeframe.label == model.get('label') and not that.default_timeframe()
        model.set('selected', true)

      view = new TimeframeView({model: model})
      that.el.grab(view.render().el)
    )
})

