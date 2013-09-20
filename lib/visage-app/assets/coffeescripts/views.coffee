#
# Views
#
DimensionView = Backbone.View.extend({
  tagName: 'li',
  className: 'item',
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
      'class': "#{name} checkbox",
      'title': "#{name}",
    })

    $(this.el).grab(label.grab(checkbox))

#    $(this.el).grab(checkbox)
#    $(this.el).grab(label)
    $(this.el).addEvent('click', (event) ->
      if event.target.tagName.toLowerCase() == 'li'
        checkbox = event.target.getElement('input.checkbox')
        checkbox.checked = !checkbox.checked if checkbox
        that.model.set('checked', !that.model.get('checked'))
    )
})

DimensionCollectionView = Backbone.View.extend({
  tagName: 'ul',
  className: 'unstyled dimensioncollection',
  initialize: () ->
    that = this
    container = $(that.options.container)

    if linked = that.options.linked
      linked.on('change', that.filter, that)

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
        'class': 'item toggle',
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

  filter: () ->
    that = this
    conditions = that.options.linked.selected().map((item) -> item.id)
    if conditions.length > 0
      that.collection.setConditions(conditions)
      that.collection.fetch({
        success: (collection) ->
          list = that.render().el
          that.options.container.grab(list)
      })
    else
      that.collection.reset
      that.options.container.getElement('ul.dimensioncollection').empty()
})

ProfileView = Backbone.View.extend({
  tagName:   'form'
  className: 'profile'
  initialize: () ->
    that = this
    #this.listenTo(that.model, "change", that.render)
})

Highcharts.setOptions({
  global: {
    useUTC: false
  }
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
            formatValue(this.value, {
              'precision': 1,
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
        animation: false
        shadow: false
        shared: true
        useHTML: true
        formatter: () ->
          options = {
            'precision': 1
            'min': min
            'max': max
          }

          s = ''
          s += '<small>'
          s += "<span style='font-weight: bold'>Time:</span> "
          s += formatDate(this.points[0].key)
          s += '</small>'
          s += '<table>'
          this.points.each((point, index) ->
            s += "<tr>"
            s += "<td style='color: " + point.series.color + "'>" + point.series.name + ": </td>"
            s += "<td style='text-align: left'>" + formatValue(point.y, options) + "</td>"
            s += "</tr>"
          )
          s += '</table>'
      }
      legend: {
        layout: 'horizontal',
        align: 'center',
        verticalAlign: 'top',
        y: 320,
        borderWidth: 0,
        floating: true,
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

SuccessView = "
<form id='share' class='share'>
  <div class='row'>
    Share this profile of graphs with others:
  </div>
  <div class='row permalink'>
    <a href='{{model.permalink}}' target='_profile_{{model.id}}'>{{model.permalink}}</a>
  </div>
  <hr>
  <div class='row'>
    <label>Timeframe</label>
    <p>
      <input id='profile-timeframe-absolute' name='profile[timeframe]' class='radio' type='radio' value='absolute' {{#if model.isAbsolute}}checked{{/if}}/>
      <label for='profile-timeframe-absolute' class='radio'>Absolute</label>
      - view the time as currently displayed on the graphs (<em>Start: {{timeframe.start}}</em>).
    </p>
    <p>
      <input id='profile-timeframe-relative' name='profile[timeframe]' class='radio' type='radio' value='{{ timeframe.label }}'{{#if model.isRelative}}checked{{/if}}/>
      <label for='profile-timeframe-relative' class='radio'>Relative</label>
      - view the time as a sliding window of &quot;{{ timeframe.label }}&quot;.
    </p>
  </div>
  <hr/>
  <div class='row question'>
    <input id='profile-anonymous' name='profile[anonymous]' class='checkbox' type='checkbox' {{#model.isNotAnonymous}}checked=true{{/model.isNotAnonymous}} value='false'>
    <label for='profile-anonymous'>Name this profile</label>
    <p>Naming a profile is helpful if you need to refer back to a collection of graphs.</p>
    <p>If you don't name the profile, you can still access it via the link above.</p>
  </div>
  <hr class='named'/>
  <div class='row text named'>
    <label for='profile-name'>Profile name</label>
    <input id='profile-name' name='profile[name]' class='text' type='text' value='{{model.name}}'>
  </div>
  <hr class='named'/>
  <div class='row text named'>
    <label for='profile-tags'>Tags<span class='tip'> (comma separated)</label>
    <input id='profile-tags' tags='profile[tags]' class='text' type='text' value='{{model.tags}}'>
  </div>
</form>
"

FailureView = """
  <div id='errors'>
    {{#each model}}
    <div class='error message'><strong>Error:</strong> {{this}}</div>
    {{/each}}
  </div>
"""

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

    shareToggler.addEvent('click', (() ->
      current = Backbone.history.fragment.toString()
      profile = window.profile

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

      switch
        # Save the profile if it is new.
        when profile.isNew()
          profile.set({
            anonymous: true,
          })

          profile.save({}, {
            success: ((profile, response, options) ->
              window.Application.navigate("profiles/#{profile.id}", {trigger: true})
              this.displayShareModal()
            ).bind(this)
            error: ((model, xhr, options) ->
              response = JSON.parse(xhr.responseText)
              errors   = []
              Object.each(response.errors, ((item, key, object) ->
                item.each((message) ->
                  errors.include("#{key.capitalize()} #{message}")
                )
              ))
              this.displayShareModal({template: 'failure', model: errors})
            ).bind(this)
          })
        # Create a new profile when updating an anonymous profile
        when profile.dirty() and profile.isAnonymous()
          window.profile = profile = profile.clone()

          profile.unset('id')

          profile.save({}, {
            success: ((profile, response, options) ->
              window.Application.navigate("profiles/#{profile.id}", {trigger: true})
              this.displayShareModal()
            ).bind(this)

            error: ((model, xhr, options) ->
              console.log(model, xhr, options)
            ).bind(this)
          })
        # Update existing profile if it is not anonymous
        when profile.dirty() and profile.isNotAnonymous()
          profile.save({}, {
            success: ((profile, response, options) ->
              this.displayShareModal()
            ).bind(this)

            error: ((model, xhr, options) ->
              console.log(model, xhr, options)
            ).bind(this)
          })
        else
          this.displayShareModal()
    ).bind(this))

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

  displayShareModal: (options={}) ->
    options.template ||= 'success'
    options.model    ||= window.profile

    modal = new LightFace({
      width:     600,
      draggable: true,
      title:     'Share profile',
      content:   "<img src='/images/loader.gif'/>",
      buttons: [
        {
          title: 'Delete',
          color: 'red',
          event: () ->
            destroy = confirm('Are you sure you want to delete this profile?')
            if destroy
              window.profile.destroy({
                success: (model, response) ->
                  window.location = '/profiles'
              })
        }
        {
          title: "Close",
          color: 'blue',
          event: () ->
            this.close()
            #this.destroy()
        }
        {
          title: 'Save',
          color: 'green',
          event: () ->
            form = this.messageBox.getElementById('share')
            form.set('send', {
              url: window.profile.url({json: false})
              onSuccess: ((responseText, responseXML) ->
                this.close()
                #this.destroy()
              ).bind(this)
            })
            form.send()
        }
      ],
      resetOnScroll: true,
    });

    [ 'delete', 'save', 'close' ].each((title) ->
      modal.showButton(title.capitalize()).set('id', "share-#{title}")
      modal.showButton(title.capitalize()).set('class', 'action')
      modal.showButton(title.capitalize()).getParent().set('id', "share-#{title}-label")
    )

    modal.open()

    # Inject content into the modal
    source   = eval((options.template.capitalize() + 'View'))
    template = Handlebars.compile(source)
    timeframe = JSON.parse(Cookie.read('timeframe'))
    timeframe.start  = new Date(timeframe.start * 1000).format("%Y/%m/%d at %H:%M")
    timeframe.finish = new Date(timeframe.finish * 1000)
    context  = { model: options.model, timeframe: timeframe }
    html     = template(context)
    modal.messageBox.set('html', html)

    # FIXME(auxesis): consider moving these into a callback on a dedicated view
    switch options.template
      when 'success'
        # If the profile is anonymous, hide the named profile options
        if window.profile.get('anonymous')
          modal.messageBox.getElements('.named').each((element) -> element.hide())

        # Toggle the display of the named profile options
        modal.messageBox.getElementById('profile-anonymous').addEvent('click', (event) ->
          modal.messageBox.getElements('.named').each((element) -> element.toggle())
        )
      when 'failure'
        # Remove buttons, only display "Close" as it's the only valid action
        [ 'delete', 'save' ].each((title) ->
          modal.showButton(title.capitalize()).getParent().dispose()
        )
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

      # FIXME(auxesis): use of global variable window - is this the best pattern?
      window.graphs.models.each((graph) ->
        graph.set(attrs)
        graph.fetch(
          success: (model, response) ->
            # FIXME(auxesis): use of global variable window - is this the best pattern?
            window.graphsView.views.each((view) ->
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

    toggler = $('timeframe-toggler')
    toggler.addEvent('click', () ->
      that.el.fade('toggle')
    )

    timeframe = JSON.decode(Cookie.read('timeframe'))
    if timeframe and timeframe.label
      label = $('timeframe-label')
      label.set('html', timeframe.label)

  default_timeframe: () ->
    that = this
    that.collection.find((model) -> model.get('default'))

  selected_timeframe: () ->
    that = this
    that.collection.find((model) -> model.get('selected'))

  render: () ->
    that = this
    that.el.empty()
    timeframe = JSON.decode(Cookie.read('timeframe'))
    selected  = false

    that.collection.each((model) ->

      if not selected
        switch
          # Pre-selected timeframe
          when model == that.selected_timeframe()
            that.setTimeframe(model)
            selected = true

          # Cookie timeframe
          when timeframe and timeframe.label == model.get('label')
            that.setTimeframe(model)
            selected = true

      view = new TimeframeView({model: model})
      that.el.grab(view.render().el)
    )

  setTimeframe: (model) ->
    model.set('selected', true)
    label = $('timeframe-label')
    label.set('html', model.get('label'))

})

