/*
 * visageBase()
 *
 * Base class for fetching data and setting graph options.
 * Should be used by other classes to build specialised graphing behaviour.
 *
 */
var visageBase = new Class({
    Implements: [Options, Events],
    options: {
        width: 900,
        height: 220,
        gridBorderColour: '#ccc',
        shade: false,
        secureJSON: false,
        httpMethod: 'get'
    },
    initialize: function(element, host, plugin, options) {
        this.parentElement = element;
        this.setOptions(options);
        this.options.host = host;
        this.options.plugin = plugin;
        data = new Hash()
        if($chk(this.options.start)) {
            data.set('start', this.options.start)
        }
        if($chk(this.options.finish)) {
            data.set('finish', this.options.finish)
        }
        this.requestData = data;
        this.getData(); // calls graphData
    },
    dataURL: function() {
        var url = ['data', this.options.host, this.options.plugin]
        // if the data exists on another host (useful for embedding)
        if ($defined(this.options.baseurl)) {
            url.unshift(this.options.baseurl.replace(/\/$/, ''))
        }
        // for specific plugin instances
        if ($chk(this.options.pluginInstance)) {
            url.push(this.options.pluginInstance)
        }
        // if no url is specified
        if (!url[0].match(/http\:\/\//)) {
            url[0] = '/' + url[0]
        }
        return url.join('/')
    },
    getData: function() {
        this.request = new Request.JSONP({
            url: this.dataURL(),
            data: this.requestData,
            secure: this.options.secureJSON,
            method: this.options.httpMethod,
            onComplete: function(json) {
                this.graphData(json);
            }.bind(this),
            onFailure: function(header, value) {
                $(this.parentElement).set('html', header)
            }.bind(this)
        });

        this.request.send();
    },
    graphName: function() {
        name = $chk(this.options.name) ? this.options.name : this.options.plugin
        return name
    },
});


/*
 * visageGraph()
 *
 * General purpose graph for rendering data from a single plugin
 * with multiple plugin instances.
 *
 * Builds upon visageBase().
 *
 */
var visageGraph = new Class({
    Extends: visageBase,
    Implements: Chain,
    // assemble data to graph, then draw it
    graphData: function(data) {
        this.response = data
        this.buildDataStructures()
        this.buildLabels()

        this.drawGraph()
    },
    buildDataStructures: function () {
        var series  = this.series = []
        var host    = this.options.host
        var plugin  = this.options.plugin
        var data    = this.response

        $each(data[host][plugin], function(instance, iname) {
            $each(instance, function(metric, mname) {
                // FIXME: refactor this horribleness out
                if ( !$defined(this.x) ) { this.x = this.buildXAxis(metric) }
                var set = {
                    name:   [ host, plugin, iname, mname ],
                    data:   metric.data,
                    colors: metric.color
                };

                series.push(set)
            }, this);
        }, this);
    },
    buildXAxis: function(metric) {
        var start    = metric.start.toInt(),
            finish   = metric.finish.toInt(),
            length   = metric.data.length,
            interval = (finish - start) / length,
            time     = start,
            x        = []

        while (time < finish) {
            var d = new Date(time * 1000)

            x.push(d)
            time += interval
        }
        return x
    },
    buildLabels: function () {
        var series = this.series,
            name;

        series.each(function(set) {
            var host     = 0,
                plugin   = 1,
                instance = 2,
                metric   = 3,
                labels   = set['name'],
                name;

            name = labels[2]
            name = name.replace(labels[1], '')
            name = name.replace(/^[-|_]*/, '')

//            name = name.replace('tcp_connections', '')
//            name = name.replace('ps_state', '')
//            name = name.replace(plugin.split('-')[0], '')
//            name += metric == "value" ? "" : " (" + metric + ")"
//            name = name.replace(/^[-|_]*/, '')

            set['name'] = name
        });
    },
    drawGraph: function() {
        var series  = this.series,
            title   = this.graphName(),
            x       = this.x,
            element = this.parentElement


        this.chart = new Highcharts.Chart({
            chart: {
              renderTo: element,
              defaultSeriesType: 'spline',
              marginRight: 130,
              marginBottom: 25,
              zoomType: 'xy'
            },
            title: {
              text: title
            },
            xAxis: {
              categories: x,
              type: 'datetime'
            },
            yAxis: {
              title: {
                text: 'Temperature (C)'
              },
              plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
              }]
            },
            labels: {
              rotation: -45,
              align: 'right',
              style: {
                font: 'normal 13px Verdana, sans-serif'
              }
            },
            plotOptions: {
              series: {
                marker: {
                  enabled: false,
                  states: {
                    hover: {
                      enabled: true
                    }
                  }
                }
              }
            },
            tooltip: {
              formatter: function() {
                          return '<b>'+ this.series.name +'</b><br/>'+
                  this.x + ': ' + this.y + 'C';
              }
            },
            legend: {
              layout: 'vertical',
              align: 'right',
              verticalAlign: 'top',
              x: -10,
              y: 100,
              borderWidth: 0
            },
            series: series
          });

        //this.formatAxes();
    },
    cleanXAxis: function(data) {
        /* clean up graph labels */
        this.x.each(function (time) { });
    },
    formatAxes: function() {

        $each(this.graph.axis[1].text.items, function (value) {
            // FIXME: no JS reference on train means awful rounding hacks!
            // if you are reading this, it's a bug!
            if (value.attr('text') > 1073741824) {
                var label = value.attr('text') / 1073741824;
                var unit = 'g'
            } else if (value.attr('text') > 1048576) {
                // and again :-(
                var label = value.attr('text') / 1048576;
                var unit = 'm'
            } else if (value.attr('text') > 1024) {
                var label = value.attr('text') / 1024;
                var unit = 'k';
            } else {
                var label = value.attr('text');
                var unit = ''
            }

            var decimal = label.toString().split('.')
            if ($chk(this.previous) && this.previous.toString()[0] == label.toString()[0] && decimal.length > 1) {
                var round = '.' + decimal[1][0]
            } else {
                var round = ''
            }

            value.attr({'text': Math.floor(label) + round + unit})
            this.previous = value.attr('text')
        });

    }
});

//    buildEmbedder: function() {
//        var pre = new Element('textarea', {
//                'id': 'embedder',
//                'class': 'embedder',
//                'html': this.embedCode(),
//                'styles': {
//                    'width': '500px',
//                    'padding': '3px'
//                }
//        });
//        this.embedderContainer.grab(pre);
//
//        var slider = new Fx.Slide(pre, {
//            duration: 200
//        });
//
//        slider.hide();
//
//        var toggler = new Element('a', {
//                'id': 'toggler',
//                'class': 'toggler',
//                'html': '(embed)',
//                'href': '#',
//                'styles': {
//                    'font-size': '0.7em',
//                }
//        });
//        toggler.addEvent('click', function(e) {
//            e.stop();
//            slider.toggle();
//        });
//        this.embedderTogglerContainer.grab(toggler);
//    },
//    embedCode: function() {
//        baseurl = "{protocol}//{host}".substitute({'host': window.location.host, 'protocol': window.location.protocol});
//        code = "<script src='{baseurl}/javascripts/visage.js' type='text/javascript'></script>".substitute({'baseurl': baseurl});
//        code += "<div id='graph'></div>"
//        code += "<script type='text/javascript'>window.addEvent('domready', function() { var graph = new visageGraph('graph', '{host}', '{plugin}', ".substitute({'host': this.options.host, 'plugin': this.options.plugin});
//        code += "{"
//        code += "width: 900, height: 220, gridWidth: 800, gridHeight: 200, baseurl: '{baseurl}'".substitute({'baseurl': baseurl});
//        code += "}); });</script>"
//        return code.replace('<', '&lt;').replace('>', '&gt;')
//    },
//    buildDateSelector: function() {
//            /*
//             * container
//             *   \
//             *    - form
//             *        \
//             *         - select
//             *         |   \
//             *         |    - option
//             *         |    |
//             *         |    - option
//             *         |
//             *         - submit
//             */
//            var currentDate = new Date;
//            var currentUnixTime = parseInt(currentDate.getTime() / 1000);
//
//            var container = $(this.timescaleContainer);
//            var form = new Element('form', {
//                    'method': 'get',
//                    'events': {
//                        'submit': function(e, foo) {
//                            e.stop();
//
//                            /*
//                             * Get the selected option, turn it into a hash for
//                             * getData() to use.
//                             */
//                            data = new Hash()
//                            if (e.target.getElement('select').getSelected().get('html') == 'selected') {
//                                data.set('start', this.graph.selectionStart);
//                                data.set('finish', this.graph.selectionFinish);
//                            } else {
//                                e.target.getElement('select').getSelected().each(function(option) {
//                                    split = option.value.split('=')
//                                    data.set(split[0], split[1])
//                                    currentTimePeriod = option.get('html') // is this setting a global?
//                                }, this);
//                            }
//                            this.requestData = data
//
//                            /* Nuke graph + labels. */
//                            this.graph.remove();
//                            delete this.x;
//                            $(this.labelsContainer).empty();
//                            $(this.timescaleContainer).empty();
//                            $(this.embedderContainer).empty();
//                            $(this.embedderTogglerContainer).empty();
//                            if ($defined(this.graph.selection)) {
//                                this.graph.selection.remove();
//                            }
//                            /* Draw everything again. */
//                            this.getData();
//                        }.bind(this)
//                    }
//            });
//
//            var select = new Element('select', { 'class': 'date timescale' });
//            var timescales = new Hash({ 'hour': 1, '2 hours': 2, '6 hours': 6, '12 hours': 12,
//                                        'day': 24, '2 days': 48, '3 days': 72,
//                                        'week': 168, '2 weeks': 336, 'month': 672 });
//            timescales.each(function(hour, label) {
//                var current = this.currentTimePeriod == 'last {label}'.substitute({'label': label });
//                var value = "start={start}".substitute({'start': currentUnixTime - (hour * 3600)});
//                var html = 'last {label}'.substitute({'label': label });
//
//                var option = new Element('option', {
//                    html: html,
//                    value: value,
//                    selected: (current ? 'selected' : '')
//
//                });
//                select.grab(option)
//            });
//
//            var submit = new Element('input', { 'type': 'submit', 'value': 'show' });
//
//            form.grab(select);
//            form.grab(submit);
//            container.grab(form);
//    },



// May be useful

//    buildLabels: function() {
//        this.ys.each(function(set, index) {
//            var path     = this.graph.lines[index],
//                color    = this.colors[index]
//                plugin   = this.options.plugin
//                instance = this.instances[index]
//                metric   = this.metrics[index]
//
//            var container = new Element('div', {
//                'class': 'label plugin',
//                'styles': {
//                    'padding': '0.2em 0.5em 0',
//                    'float': 'left',
//                    'width': '180px',
//                    'font-size': '0.8em'
//                },
//                'events': {
//                    'mouseover': function(e) {
//                        e.stop();
//                        path.animate({'stroke-width': 3}, 300);
//                        //path.toFront();
//                    },
//                    'mouseout': function(e) {
//                        e.stop();
//                        path.animate({'stroke-width': 1.5}, 300);
//                        //path.toBack();
//                    },
//                    'click': function(e) {
//                        e.stop();
//                        path.attr('opacity') == 0 ? path.animate({'opacity': 1}, 350) : path.animate({'opacity': 0}, 350);
//                    }
//                }
//            });
//
//            var box = new Element('div', {
//                'class': 'label plugin box ' + metric,
//                'html': '&nbsp;',
//                'styles': {
//                      'background-color': color,
//                      'width': '48px',
//                      'height': '18px',
//                      'float': 'left',
//                      'margin-right': '0.5em'
//                }
//            });
//
//            // plugin/instance/metrics names can be unmeaningful. make them pretty
//            var desc = new Element('span', {
//                'class': 'label plugin description ' + metric,
//                'html': name
//            });
//
//            container.grab(box);
//            container.grab(desc);
//            $(this.labelsContainer).grab(container);
//
//        }, this);
//    }
//})
//
