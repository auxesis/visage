window.addEvent('domready', function() {
  //
  // Hosts
  //

  var Host = Backbone.Model.extend({
    hostname: function() {
      return this.get('fqdn').split('.')[0]
    },
  });

  var Hosts = Backbone.Collection.extend({
    url: '/data',
    model: Host,
    parse: function(response) {
      var attrs = response.hosts.map(function(host) {
        return { id: host }
      });

      return attrs
    }
  });

  var hosts = new Hosts;

  hosts.on('reset', function(hosts) {
    var container = $('hosts');
    hosts.pluck('id').each(function(id) {
      var el = new Element('li', { 'html': id });
      container.grab(el)
    });
  });

  hosts.fetch();

  //
  // Metrics
  //

  var Metric = Backbone.Model.extend({
    plugin: function() {
      return this.get('id').split('/')[0]
    },
    instance: function() {
      return this.get('id').split('/')[1]
    },
  });

  var Metrics = Backbone.Collection.extend({
    url: '/data/*',
    model: Metric,
    parse: function(response) {
      var attrs = response.metrics.map(function(metric) {
        return { id: metric }
      });

      return attrs
    }
  });

  var metrics = new Metrics;

  metrics.on('reset', function(metrics) {
    var container = $('metrics');
    metrics.pluck('id').each(function(id) {
      var el = new Element('li', { 'html': id });
      container.grab(el)
    });
  });

  metrics.fetch();

});
