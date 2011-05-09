function formatSeriesLabel(labels) {
    var host     = labels[0],
        plugin   = labels[1],
        instance = labels[2],
        metric   = labels[3],
        name;


    if (plugin == "irq") {
        name = name.replace(/^/, 'irq ')
    }
    // Plugin specific labeling
    else if (plugin == "interface") {
        name = instance.replace(/^if_(.*)-(.*)/, '$2 $1') + ' (' + metric + ')'
    }
    else if (["processes", "memory"].contains(plugin) || plugin.test(/^cpu-\d+/) ) {
        name = instance.split('-')[1]
    }
    else if (plugin == "swap") {
        if (instance.test(/^swap_io/)) {
            name = instance.replace(/^swap_(\w*)-(.*)$/, '$1 $2')
        }
        if (instance.test(/^swap-/)) {
            name = instance.split('-')[1]
        }
    }
    else if (plugin == "load") {
        name = metric.replace(/^\((.*)\)$/, '$1')
    }
    else if (plugin.test(/^disk/)) {
        name = instance.replace(/^disk_/, '') + ' (' + metric + ')'
    }
    else if (["entropy","users"].contains(plugin)) {
        name = metric
    }
    else if (plugin == "uptime") {
        name = instance
    }
    else if (plugin == "ping") {
        if (instance.test(/^ping_/)) {
            name = instance.replace(/^ping_(.*)-(.*)$/, '$1 $2')
        } else {
            name = metric + ' ' + instance.split('-')[1]
        }
    }
    else if (plugin.test(/^vmem/)) {
        if (instance.test(/^vmpage_number-/)) {
            name = instance.replace(/^vmpage_number-(.*)$/, '$1').replace('_', ' ')
        }
        if (instance.test(/^vmpage_io/)) {
            name = instance.replace(/^vmpage_io-(.*)$/, '$1 ') + metric
        }
        if (instance.test(/^vmpage_faults/)) {
            name = metric.trim() == "minflt" ? 'minor' : 'major'
            name += ' faults'
        }
        if (instance.test(/^vmpage_action-/)) {
            name = instance.replace(/^vmpage_action-(.*)$/, '$1').replace('_', ' ')
        }
    }
    else if (plugin.test(/^tcpconns/)) {
        name = instance.split('-')[1].replace('_', ' ')
    }
    else if (plugin.test(/^tail/)) {
        name = plugin.split('-').slice(1).join('-') + ' '
        name = instance.split('-').slice(1).join('-')
    }
    else if (plugin == "apache") {
        var stash = instance.split('_')[1]
        if (stash.test(/^scoreboard/)) {
          name = 'connections: ' + stash.split('-')[1]
        } else {
          name = stash
        }
    }
    else if ( plugin.test(/^curl_json/) ) {
        var stash = instance.split('-')[2];
        var stash = stash.replace(/[-|_]/, ' ');
        name = stash
    }
    else {
        // Generic label building
        name = instance
        name = name.replace(plugin.split('-')[0], '')
        name += metric == "value" ? "" : " (" + metric + ")"
        name = name.replace(/^[-|_]*/, '')
        name = name.trim().replace(/^\((.*)\)$/, '$1')
    }
    return name.trim()
}

function formatValue(value, options) {
    var precision = options.precision,
        min       = options.min,
        max       = options.max;

    switch(true) {
        case (Math.abs(max) > 1125899906842624):
            var label = value / 1125899906842624,
                unit  = 'P';
            break
        case (Math.abs(max) > 1099511627776):
            var label = value / 1099511627776,
                unit  = 'T';
            break
        case (Math.abs(max) > 1073741824):
            var label = value / 1073741824,
                unit  = 'G';
            break
        case (Math.abs(max) > 1048576):
            var label = value / 1048576,
                unit  = 'M';
            break
        case (Math.abs(max) > 1024):
            var label = value / 1024,
                unit  = 'K';
            break
        default:
            var label = value,
                unit  = '';
            break
    }

    var rounded = label.round(precision)

    return rounded + unit
}

function formatDate(d) {
  var datetime = new Date(d * 1000)
  return datetime.format("%Y-%m-%d %H:%M:%S UTC%T")
}

function formatPluginName(name) {
    if (name.test(/^curl_json/)) {
        name = name.split('-')[1].replace(/(-|_)/, ' ');
    }
    return name
}


/*
 * visageBase()
 *
 * Base class for fetching data and setting graph options.
 * Should be used by other classes to build specialised graphing behaviour.
 *
 */
var visageBase = new Class({
    Implements: [ Options, Events ],
    options: {
        secureJSON: false,
        httpMethod: 'get',
        live: false
    },
    initialize: function(element, host, plugin, options) {
        this.parentElement  = element
        this.options.host   = host
        this.options.plugin = plugin
        this.setOptions(options)

        var data = new Hash()
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
            url:        this.dataURL(),
            data:       this.requestData,
            secure:     this.options.secureJSON,
            method:     this.options.httpMethod,
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
        if ($chk(this.options.name)) {
            var name = this.options.name
        } else {
            var name = [ formatPluginName(this.options.plugin),
                         'on',
                         this.options.host ].join(' ')
        }
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
        this.lastStart  = this.series[0].data[0][0]
        this.lastFinish = this.series[0].data.getLast()[0]

        switch(true) {
            case $defined(this.chart) && this.requestData['live']:
                this.series.each(function(series, index) {
                    var point = series.data[1];
                    this.chart.series[index].addPoint(point, false);
                }, this);
                this.chart.redraw();
                break;
            case $defined(this.chart):
                this.series.each(function(series, index) {
                    this.chart.series[index].setData(series.data, false);
                }, this);

                /* Reset the zoom */
                //this.chart.toolbar.remove('zoom');
                this.chart.xAxis.concat(this.chart.yAxis).each(function(axis) {
                    axis.setExtremes(null,null,false);
                });

                this.chart.redraw();
                break;
            default:
                this.drawChart()
                break;
        }
    },
    buildDataStructures: function (data) {
        var series  = this.series = []
        var host    = this.options.host
        var plugin  = this.options.plugin
        var data    = data ? data : this.response

        $each(data[host][plugin], function(instance, iname) {
            $each(instance, function(metric, mname) {
                var start    = metric.start,
                    finish   = metric.finish,
                    interval = (finish - start) / metric.data.length;

                var data     = metric.data.map(function(value, index) {
                    var x = start + index * interval,
                        y = value;
                    return [ x, y ];
                });

                var set = {
                    name: [ host, plugin, iname, mname ],
                    data: data,
                };

                series.push(set)
            }, this);
        }, this);

        return series
    },
    getSeriesMinMax: function(series) {
        var min, max;

        series.each(function(set) {
            values = set.data.map(function(point) {
                var value = point[1];
                return value
            });

            var setMin = values.min()
            var setMax = values.max()

            if ($chk(min)) {
                min = min > setMin ? setMin : min
            } else {
                min = setMin
            }

            if ($chk(max)) {
                max = max < setMax ? setMax : max
            } else {
                max = setMax
            }
        });

        return {'min': min, 'max': max};
    },
    drawChart: function() {
        var series  = this.series,
            title   = this.graphName(),
            element = this.parentElement,
            ytitle  = formatPluginName(this.options.plugin),
            min,
            max;

        /* Get the maximum value across all sets.
         * Used later on to determine the decimal place in the label. */
        meta = this.getSeriesMinMax(series);
        var min = meta.min,
            max = meta.max;

        this.chart = new Highcharts.Chart({
            chart: {
                renderTo: element,
                defaultSeriesType: 'line',
                marginRight: 200,
                marginBottom: 25,
                zoomType: 'xy',
                height: 300,
                events: {
                    load: function(e) {
                        setInterval(function() {
                            if (this.options.live) {
                                var data = { 'start':  this.lastFinish,
                                             'finish': this.lastFinish + 10,
                                             'live':   true };
                                this.requestData = data;
                                this.getData()
                            }
                        }.bind(this), 10000);
                    }.bind(this)
                }
            },
            title: {
              text: title,
              style: {
                fontSize: '20px',
                fontWeight: 'bold',
                color: "#333333"
              }
            },
            xAxis: {
              type: 'datetime',
              labels: {
                y: 20,
                formatter: function() {
                  var d = new Date(this.value * 1000)
                  return d.format("%H:%M")
                }
              },
                title: {
                    text: null
                }
            },
            yAxis: {
              title: {
                text: ytitle
              },
              maxPadding: 0,
              plotLines: [{
                width: 0.5,
              }],
              labels: {
                    formatter: function() {
                        var precision = min - max < 1000 ? 2 : 0,
                            value     = formatValue(this.value, {
                                            'precision': precision,
                                            'min':       min,
                                            'max':       max
                                        });
                        return value
                    }
              }
            },
            plotOptions: {
              series: {
                shadow: false,
                marker: {
                  enabled: false,
                  stacking: 'normal',
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
                var tip;
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
              }
            },
            legend: {
                layout: 'vertical',
                align: 'right',
                verticalAlign: 'top',
                x: -10,
                y: 60,
                borderWidth: 0,
                itemWidth: 186,
                labelFormatter: function() {
                    return formatSeriesLabel(this.name)
                },
                itemStyle: {
                    cursor: 'pointer',
                    color:  '#333333'
                },
                itemHoverStyle: {
                    color:  '#777777'
                }

            },
            series: series,
            credits: {
              enabled: false
            }
          });

          this.buildDateSelector();
    },
    buildDateSelector: function() {
        /*
         * container
         *   \
         *    - form
         *        \
         *         - select
         *         |   \
         *         |    - option
         *         |    |
         *         |    - option
         *         |
         *         - submit
         */
        var currentDate = new Date;
        var currentUnixTime = parseInt(currentDate.getTime() / 1000);

        var container = $(this.parentElement);
        var form = new Element('form', {
            'method': 'get',
            'events': {
                'submit': function(e, foo) {
                    e.stop();
                    e.target.getElement('select').getSelected().each(function(option) {
                        value = parseInt(option.value.split('=')[1])
                        data = { 'start': value }
                    });
                    this.requestData = data;

                   /* Draw everything again. */
                    this.getData();
                }.bind(this)
            }
        });

        var select = new Element('select', { 'class': 'date timescale' });
        var timescales = new Hash({ 'hour': 1, '2 hours': 2, '6 hours': 6, '12 hours': 12,
                                    'day': 24, '2 days': 48, '3 days': 72,
                                    'week': 168, '2 weeks': 336, 'month': 672 });
        timescales.each(function(hour, label) {
            var current = this.currentTimePeriod == 'last {label}'.substitute({'label': label });
            var value = "start={start}".substitute({'start': currentUnixTime - (hour * 3600)});
            var html = 'last {label}'.substitute({'label': label });

            var option = new Element('option', {
                html: html,
                value: value,
                selected: (current ? 'selected' : '')
            });
            select.grab(option)
        });

        var submit = new Element('input', { 'type': 'submit', 'value': 'show' });

        var liveToggler = new Element('input', {
            'type': 'checkbox',
            'id':   this.parentElement + '-live',
            'name': 'live',
            'checked': this.options.live,
            'events': {
                'click': function() {
                    this.options.live = !this.options.live
                }.bind(this)
            },
            'styles': {
                'margin-left': '4px',
                'cursor': 'pointer'
            }
        });

        var liveLabel = new Element('label', {
            'for': this.parentElement + '-live',
            'html': 'Live',
            'styles': {
                'font-family': 'sans-serif',
                'font-size':   '11px',
                'margin-left': '8px',
                'cursor': 'pointer'
            }
        });

        var exportLink = new Element('a', {
            'href': this.dataURL(),
            'html': 'Export data',
            'styles': {
                'font-family': 'sans-serif',
                'font-size':   '11px',
                'margin-left': '8px',
            },
            'events': {
                'mouseover': function(e) {
                    e.stop();
                    var url      = e.target.get('href'),
                        extremes = this.chart.xAxis[0].getExtremes(),
                        options  = { 'start':  extremes.dataMin,
                                     'finish': parseInt(extremes.dataMax) };

                    var options = new Hash(options).toQueryString(),
                        baseurl = this.dataURL(),
                        url     = baseurl += '?' + options;

                    e.target.set('href', url)
                }.bind(this)
            }
        });

        form.grab(select)
        form.grab(submit)
        form.grab(liveToggler)
        form.grab(liveLabel)
        form.grab(exportLink)
        container.grab(form, 'top')
    },



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

