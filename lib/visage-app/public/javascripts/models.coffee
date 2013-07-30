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
      that   = this
      host   = that.get('host')
      plugin = that.get('plugin')
      start  = that.get('start')
      finish = that.get('finish')
      query  = {}
      query.start  = start  if start
      query.finish = finish if finish
      query = if Object.getLength(query) > 0 then '?' + Object.toQueryString(query) else ''

      "/data/#{host}/#{plugin}#{query}"
    parse: (response) ->
      that   = this
      host   = response.host   || that.get('host')
      plugin = response.plugin || that.get('plugin')
      data   = response

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

  Timeframe = Backbone.Model.extend({
    currentUnixTime: () ->
      date = new Date
      parseInt(date.getTime() / 1000)
    relativeUnixTimeTo: (value) ->
      that = this
      that.currentUnixTime() - (Math.abs(value) * 3600)
    roundedUnixTimeTo: (value) ->
      if (value < 0)
        return new Date().decrement('month', Math.abs(value)).set('date', 1).clearTime().getTime() / 1000

      if (value > 0)
        return new Date().increment('month', value).set('date', 1).clearTime().getTime() / 1000

      return new Date().set('date', 1).clearTime().getTime() / 1000;

    toTimeAttributes: () ->
      that   = this
      unit   = that.get('unit')
      start  = that.get('start')
      finish = that.get('finish')
      attrs  = {}

      if unit == 'hours'
        attrs.start  = that.relativeUnixTimeTo(start) if start
        attrs.finish = that.relativeUnixTimeTo(finish) if finish
      else if unit == 'months'
        attrs.start  = that.relativeUnixTimeTo(start) if start
        attrs.finish = that.relativeUnixTimeTo(finish) if finish

      attrs.label = that.get('label')
      attrs
  })

  Profile = Backbone.Model.extend({
    url:   () ->
      id = document.location.pathname.split('/')[2]
      if id == 'new'
        '/profiles'
      else
        "/profiles/#{id}.json"
  })

