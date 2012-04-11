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

    return label.format({decimals: precision, suffix: unit})
}

function formatDate(d) {
  var datetime = new Date(d)
  return datetime.format("%Y-%m-%d %H:%M:%S UTC%z")
}

function formatPluginName(name) {
    if (name.test(/^curl_json/)) {
        name = name.split('-')[1].replace(/(-|_)/, ' ');
    }
    return name
}


/*
 * VisageBase()
 *
 * Base class for fetching data and setting graph options.
 * Should be used by other classes to build specialised graphing behaviour.
 *
 */
var VisageBase = new Class({
    Implements: [ Options, Events ],
    options: {
        secureJSON: false,
        httpMethod: 'get',
        live: false
    },
    initialize: function(element, host, plugin, options) {
        this.parentElement  = element;
        this.options.host   = host;
        this.options.plugin = plugin;
        this.query          = window.location.search.slice(1).parseQueryString();
        this.options        = Object.merge(this.options, this.query);
        console.dir('VisageBase initialize ... options:');
        console.dir(options)

        this.setOptions(options);

        this.requestData = new Object();
        this.requestData.start  = this.options.start;
        this.requestData.finish = this.options.finish;

        this.getData(); // calls graphData
    },
    dataURL: function() {
        var url = ['data', this.options.host, this.options.plugin];

        // if the data exists on another host (useful for embedding)
        if (this.options.baseurl) {
            url.unshift(this.options.baseurl.replace(/\/$/, ''))
        }
        // for specific plugin instances
        if (this.options.pluginInstance) {
            url.push(this.options.pluginInstance)
        }
        // if no url is specified
        if (!url[0].match(/http\:\/\//)) {
            url[0] = '/' + url[0]
        }
        var options = '';
        console.dir('this.options.percentiles in dataURL:');
        if (this.options.percentiles) {
            console.dir(this.options.percentiles);
            console.dir(this.options.percentiles.length);
            if (this.options.percentiles.length > 0) {
                options = '?percentiles=true';
            }
        }
        return url.join('/') + options;
    },
    getData: function() {
        console.dir("in getData...");
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
    title: function() {
        if ($chk(this.options.name)) {
            var title = this.options.name
        } else {
            var title = [ formatPluginName(this.options.plugin),
                          'on',
                          this.options.host ].join(' ')
        }
        return title
    },
});


/*
 * VisageGraph()
 *
 * General purpose graph for rendering data from a single plugin
 * with multiple plugin instances.
 *
 * Builds upon VisageBase().
 *
 */
var VisageGraph = new Class({
    Extends: VisageBase,
    Implements: Chain,
    // assemble data to graph, then draw it
    graphData: function(data) {
        console.dir("in graphData... got data:");
        console.dir(data);
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
                this.drawPercentiles(this.chart)
                break;
            default:
                this.drawChart()
                this.drawPercentiles(this.chart)
                break;
        }
    },
    buildDataStructures: function (data) {
        console.dir("in buildDataStructures... data:");
        console.dir(data);
        console.dir("this:");
        console.dir(this);
        var series  = this.series = []
        var host    = this.options.host
        var plugin  = this.options.plugin
        var data    = data ? data : this.response

        $each(data[host][plugin], function(instance, instanceName) {
            $each(instance, function(metric, metricName) {
                var start         = metric.start,
                    finish        = metric.finish,
                    interval = (finish - start) / metric.data.length;

                var data     = metric.data.map(function(value, index) {
                    var x = (start + index * interval) * 1000,
                        y = value;

                    return [ x, y ];
                });

                var set = {
                    name: [ host, plugin, instanceName, metricName ],
                    data: data,
                    percentile95: metric.percentile_95
                };

                series.push(set)
            }, this);
        }, this);
        console.dir("buildDataStructures is returning series:");
        console.dir(series)
        return series
    },
    getSeriesMinMax: function(series) {
        console.dir("in getSeriesMinMax... series:");
        console.dir(series);
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
    drawPercentiles: function(chart) {

        var series = this.series;

        /* Get the maximum value across all sets.
         * Used later on to determine the decimal place in the label. */
        meta = this.getSeriesMinMax(series);
        var min = meta.min,
            max = meta.max;

        console.dir("in drawPercentiles... chart:");
        console.dir(chart);
        series.each(function(set) {
            console.log("formatting value: " + set.percentile95);
            formattedValue = formatValue(set.percentile95, { 'precision': 2, 'min': min, 'max': max });
            chart.yAxis[0].removePlotLine('95e_' + set.name[2] + set.name[3]);
            chart.yAxis[0].addPlotLine({
                id: '95e_' + set.name[2] + set.name[3],
                value: set.percentile95,
                color: '#ff0000',
                width: 1,
                zIndex: 5,
                label: {
                    text: '95e ' + set.name[3] + ": " + formattedValue
                }
            })
        });
    },
    drawChart: function() {
        console.dir("in drawChart...");

        var series  = this.series,
            title   = this.title(),
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
            series: series,
            chart: {
                renderTo:     element,
                type:         'line',
                marginRight:  0,
                marginBottom: 60,
                zoomType:     'xy',
                height:       300,
                events: {
                    load: function(e) {
                        setInterval(function() {
                            if (this.options.live) {
                                var data = { 'start':  this.lastFinish / 1000,
                                             'finish': this.lastFinish / 1000 + 10,
                                             'live':   true };
                                this.requestData = data;
                                // FIXME: for 95e plotLines - need to update them each data retrieval
                                // but perhaps 'live' just sends incremental data and so won't cause
                                // a recalculation of the 95e figures on the server side?
                                this.getData()
                            }
                        }.bind(this), 10000);
                    }.bind(this)
                }
            },
            title: {
                text: title,
                style: {
                    'fontSize':    '18px',
                    'fontWeight':  'bold',
                    'color':       '#333333',
                    'font-family': 'Bitstream Vera Sans, Helvetica Neue, sans-serif',
                }
            },
/*
            colors: [
'#204a87', '#4e9a06', '#cc0000', '#5c3566', '#f57900', '#e9b96e', '#ad7fa8', '#888a85', '#8ae234', '#75507b', '#c17d11', '#729fcf', '#73d216', '#ef2929', '#edd400', '#8f5902', '#555753', '#fce94f', '#2e3436', '#babdb6', '#3465a4', '#a40000', '#c4a000', '#ce5c00', '#d3d7cf', '#fcaf3e', '#eeeeec',
            ],
*/
            xAxis: {
                title: {
                    text: null
                },
                lineColor: "#aaa",
                tickColor: "#aaa",
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
                title: {
                    text: null
                },
                startOnTick:   false,
                minPadding:    0.065,
                endOnTick:     false,
                gridLineColor: "#dddddd",
                labels: {
                    formatter: function() {
                        var precision = 1,
                            value     = formatValue(this.value, {
                                            'precision': precision,
                                            'min':       min,
                                            'max':       max
                                        });
                        return value
                    }
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
                layout: 'horizontal',
                align: 'center',
                verticalAlign: 'top',
                y: 255,
                borderWidth: 0,
                floating: true,
                labelFormatter: function() {
                    return formatSeriesLabel(this.name)
                },
                itemStyle: {
                    cursor: 'pointer',
                    color:  '#333333'
                },
                itemHoverStyle: {
                    color:  '#888'
                }

            },
            credits: {
                enabled: false
            }
          });

          this.buildDateSelector();
    },
    buildDateSelector: function() {
        console.dir("in buildDateSelector...");
        /*
         * container
         *   \
         *    - form
         *        \
         *         - select
         *             \
         *              - option
         *              |
         *              - option
         */
        var currentDate = new Date;
        var currentUnixTime = parseInt(currentDate.getTime() / 1000);

        var container = $(this.parentElement);
        var form      = this.form = new Element('form', {
            'method': 'get',
            'styles': {
                'text-align': 'right',
            },
            'events': {
                'submit': function(e) {
                    this.requestData = this.form.getElement('select').getSelected()[0].value.parseQueryString()
                   /* Draw everything again. */
                    this.getData();
                }.bind(this)
            }
        });

        /* Select dropdown */
        var select = this.select = new Element('select', {
            'class':  'date timescale',
            'styles': {
                'margin-bottom':    '3px',
                'border':           '1px solid #aaa',
            },
            'events': {
                'change': function(e) {
                    e.target.form.fireEvent('submit', e)
                }
            }
        });

        /* Timescales available in the dropdown */
        var timescales = new Hash({ '1 hour':   1,
                                    '2 hours':  2,
                                    '6 hours':  6,
                                    '12 hours': 12,
                                    '24 hours': 24,
                                    '3 days':   72,
                                    '7 days':   168,
                                    '2 weeks':  336,
                                    '1 month':  774,
                                    '3 month':  2322,
                                    '6 months': 4368,
                                    '1 year':   8760,
                                    '2 years':  17520 });

        timescales.each(function(hour, label) {
            var current = this.currentTimePeriod == 'last {label}'.substitute({'label': label });
            var value   = "start={start}".substitute({'start': currentUnixTime - (hour * 3600)});
            var html    = 'last {label}'.substitute({'label': label });

            var option = new Element('option', {
                'html':     html,
                'value':    value,
                'selected': (current ? 'selected' : ''),
            });
            select.grab(option)
        });

        /* Calendar month timescales dropdown */
        var monthlyTimescales = new Hash({ 'current month': 0,
                                           'previous month': 1 });

        monthlyTimescales.each(function(monthsAgo, label) {
            console.dir("monthlyTimescales.each(" + monthsAgo + ", " + label + ")");
            var current    = this.currentTimePeriod == label;
            var value = "start=" + (new Date().decrement('month', monthsAgo).set('date', 1).set('hr', 0).set('min', 0).set('sec', 0).getTime() / 1000);
            value += '&finish=' + (new Date().decrement('month', monthsAgo - 1).set('date', 1).set('hr', 0).set('min', 0).set('sec', 0).getTime() / 1000);

            var option = new Element('option', {
                'html':     label,
                'value':    value,
                'selected': (current ? 'selected' : ''),
            });
            console.dir("monthlyTimescales select:");
            console.dir(select)
            select.grab(option)
        });

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
                'margin-right': '4px',
                'cursor': 'pointer'
            }
        });

        var liveLabel = new Element('label', {
            'for': this.parentElement + '-live',
            'html': 'Live',
            'styles': {
                'font-family': 'sans-serif',
                'font-size':   '11px',
                'margin-right': '8px',
                'cursor': 'pointer'
            }
        });

        var exportLink = new Element('a', {
            'href': this.dataURL(),
            'html': 'Export data',
            'styles': {
                'font-family':  'sans-serif',
                'font-size':    '11px',
                'margin-right': '8px',
                'color':        '#2F5A92',
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

        form.grab(exportLink)
        form.grab(liveToggler)
        form.grab(liveLabel)
        form.grab(select)
        container.grab(form, 'top')
    },
    setTimePeriodTo: function(selected) {
        console.dir("in setTimePeriodTo... selected:");
        console.dir(selected);
        var option = this.select.getElements('option').filter(function(opt) {
            return opt.text == selected.text
        })[0];

        option.set('selected', 'selected');

        this.form.fireEvent('submit')
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
//        code += "<script type='text/javascript'>window.addEvent('domready', function() { var graph = new VisageGraph('graph', '{host}', '{plugin}', ".substitute({'host': this.options.host, 'plugin': this.options.plugin});
//        code += "{"
//        code += "width: 900, height: 220, gridWidth: 800, gridHeight: 200, baseurl: '{baseurl}'".substitute({'baseurl': baseurl});
//        code += "}); });</script>"
//        return code.replace('<', '&lt;').replace('>', '&gt;')
//    },

