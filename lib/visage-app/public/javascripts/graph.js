function setStacked(chart, stacking) {
    for(var i=0;i<chart.series.length;i++)
    {
        var serie = chart.series[0];
        var newSeries = {
            type: stacking ? 'area' : 'line',
            name: serie.name,
            color: serie.color,
            data: serie.options.data,
            stacking: stacking ? 'normal' : null,
        }
        chart.addSeries(newSeries, false, false);
        serie.remove();
    }
}

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

function formatValue(v, options) {
    var precision = options.precision,
        min       = options.min,
        max       = options.max,
        base      = options.base || 1000;

    var formatting = [
        [ Math.pow(base, 5), 'P' ],
        [ Math.pow(base, 4), 'T' ],
        [ Math.pow(base, 3), 'G' ],
        [ Math.pow(base, 2), 'M' ],
        [ Math.pow(base, 1), 'K' ],
    ].filter(function(item, index, array) {
        return Math.abs(v) > item[0]
    })[0];

    if (!formatting) { formatting = [ 1, ' ' ] }

    var value = v / formatting[0],
        unit  = formatting[1];

    var format = value.format({
        decimals: precision,
        suffix: unit,
        scientific: false,
    })

    return format
}

function formatDate(d) {
  var datetime = new Date(d)
  return datetime.format("%Y-%m-%d %H:%M:%S")
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
        live:       false,
        stacked:    false,
    },
    initialize: function(element, host, plugin, options) {
        this.parentElement  = element;
        this.options.host   = host;
        this.options.plugin = plugin;
        this.query          = window.location.search.slice(1).parseQueryString();
        this.options        = Object.merge(this.options, this.query);
        this.currentDate     = new Date;
        this.currentUnixTime = parseInt(this.currentDate.getTime() / 1000);

        this.timeframes = new Hash({
            'last 1 hour':      { start: -1,     unit: 'hours' },
            'last 2 hours':     { start: -2,     unit: 'hours' },
            'last 6 hours':     { start: -6,     unit: 'hours' },
            'last 12 hours':    { start: -12,    unit: 'hours' },
            'last 24 hours':    { start: -24,    unit: 'hours' },
            'last 3 days':      { start: -72,    unit: 'hours' },
            'last 7 days':      { start: -168,   unit: 'hours' },
            'last 2 weeks':     { start: -336,   unit: 'hours' },
            'last 1 month':     { start: -774,   unit: 'hours' },
            'last 3 months':    { start: -2322,  unit: 'hours' },
            'last 6 months':    { start: -4368,  unit: 'hours' },
            'last 1 year':      { start: -8760,  unit: 'hours' },
            'last 2 years':     { start: -17520, unit: 'hours' },
            'current month':    { start: 0,  finish: 1,  unit: 'months' },
            'previous month':   { start: -1, finish: 0,  unit: 'months' },
            'two months ago':   { start: -2, finish: -1, unit: 'months' },
            'three months ago': { start: -3, finish: -2, unit: 'months' },
        }).map(function(time) {
            var currentUnixTime = this.currentUnixTime;
            switch(true) {
                case (time.unit == 'hours'):
                    delete(time.unit) // nuke the unit, so it doesn't get transformed
                    return Object.map(time, function(value, key) {
                        return currentUnixTime - (Math.abs(value) * 3600)
                    });
                case (time.unit == 'months'):
                    delete(time.unit) // nuke the unit, so it doesn't get transformed
                    return Object.map(time, function(value, key) {
                        if (value < 0) {
                            return new Date().decrement('month', Math.abs(value)).set('date', 1).clearTime().getTime() / 1000;
                        }
                        if (value > 0) {
                            return new Date().increment('month', value).set('date', 1).clearTime().getTime() / 1000;
                        }
                        return new Date().set('date', 1).clearTime().getTime() / 1000;
                    });
            }
        }, this);

        this.setOptions(options);

        this.requestData = new Object();
        if (this.options.timeframe) {
            this.setupTimeframe();
        } else {
            this.requestData.start  = this.options.start;
            this.requestData.finish = this.options.finish;
        }

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
        if (this.options.percentiles) {
            if (this.options.percentiles.length > 0) {
                options = '?percentiles=true';
                this.options.percentile95 = true;
            }
        }
        return url.join('/') + options;
    },
    getData: function() {
        this.request = new Request.JSON({
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
        if (!!(this.options.name || this.options.name === 0)) {
            var title = this.options.name
        } else {
            var title = [ formatPluginName(this.options.plugin),
                          'on',
                          this.options.host ].join(' ')
        }
        return title
    },
    setupTimeframe: function() {
        var timeframe    = this.options.timeframe;
        var timeframes   = this.timeframes;
        this.requestData = Object.merge(this.requestData, timeframes[timeframe]);
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
        this.response = data
        this.buildDataStructures()
        this.lastStart  = this.series[0].data[0][0]
        this.lastFinish = this.series[0].data.getLast()[0]

        switch(true) {
            case (this.chart != undefined) && this.requestData['live']:
                this.series.each(function(series, index) {
                    var point = series.data[1];
                    this.chart.series[index].addPoint(point, false);
                }, this);
                this.chart.redraw();
                break;
            case (this.chart != undefined):
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
        var series  = this.series = []
        var host    = this.options.host
        var plugin  = this.options.plugin
        var data    = data ? data : this.response

        Object.each(data[host][plugin], function(instance, instanceName) {
            Object.each(instance, function(metric, metricName) {
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

        series = series.sort(function(a,b) {
            if (a.name[2] < b.name[2]) return -1;
            if (a.name[2] > b.name[2]) return 1;
            return 0
        });

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

            if (!!(min || min === 0)) {
                min = min > setMin ? setMin : min
            } else {
                min = setMin
            }

            if (!!(max || max === 0)) {
                max = max < setMax ? setMax : max
            } else {
                max = setMax
            }
        });

        return {'min': min, 'max': max};
    },
    removePercentiles: function(chart) {

        var series = this.series;

        series.each(function(set) {
            chart.yAxis[0].removePlotLine('95e_' + set.name[2] + set.name[3]);
        });
    },
    drawPercentiles: function(chart) {
        var series = this.series;

        /* Get the maximum value across all sets.
         * Used later on to determine the decimal place in the label. */
        meta = this.getSeriesMinMax(series);
        var min = meta.min,
            max = meta.max;

        series.each(function(set) {
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


                height:       350,
                plotBorderWidth: 1,
                plotBorderColor: '#020508',
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
                    formatter: function() {
                        var precision = 1,
                            value     = formatValue(this.value, {
                                            'precision': precision,
                                            'min':       min,
                                            'max':       max
                                        });
                        return value
                    },
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
                y: 320,
                borderWidth: 0,
                floating: true,
                labelFormatter: function() {
                    return formatSeriesLabel(this.name)
                },
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
         *             \
         *              - option
         *              |
         *              - option
         */
        var container = $(this.parentElement);
        var form      = this.form = new Element('form', {
            'method': 'get',
            'styles': {
                'text-align': 'right',
                'display': 'none',
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


        timeframe = this.options.timeframe;
        this.timeframes.each(function(time, label) {
            var value  = Object.toQueryString(time);
            var option = new Element('option', {
                'html':     label,
                'value':    value,
                'selected': label == timeframe,
            });
            select.grab(option)
        });

        var liveToggler = this.liveToggler = new Element('input', {
            'type': 'checkbox',
            'id':   this.parentElement + '-live',
            'name': 'live',
            'checked': this.options.live,
            'disabled': this.options.percentile95,
            'events': {
                'click': function(e) {
                    this.options.live = !this.options.live
                    if (this.options.live) {
                        // tell percentiles95Toggler to be unchecked
                        if (this.options.percentile95) {
                            this.percentile95Toggler.fireEvent('click');
                        }
                        this.percentile95Toggler.set('disabled', true);
                    } else {
                        this.requestData.live = false;
                        this.percentile95Toggler.set('disabled', false);
                        e.target.form.fireEvent('submit', e)
                    }
                }.bind(this)
            },
            'styles': {
                'margin-right': '4px',
                'cursor': 'pointer'
            }
        });

        var stackedToggler = this.stackedToggler = new Element('input', {
            'type': 'checkbox',
            'id': this.parentElement + '-stacked',
            'name': 'stacked',
            'checked': this.options.stacked,
            'disabled': this.options.percentile95,
            'events': {
                'click': function(e) {
                    this.options.stacked = !this.options.stacked
                    setStacked(this.chart, this.options.stacked)
                    if (this.options.stacked) {
                        // tell percentiles95Toggler to be unchecked
                        if (this.options.percentile95) {
                            this.percentile95Toggler.fireEvent('click');
                        }
                        this.percentile95Toggler.set('disabled', true);
                    } else {
                        this.percentile95Toggler.set('disabled', false);
                        e.target.form.fireEvent('submit', e)
                    }
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

        var percentile95Toggler = this.percentile95Toggler = new Element('input', {
            'type': 'checkbox',
            'id':   this.parentElement + '-percentile95',
            'name': 'percentile95',
            'checked': this.options.percentile95,
            'events': {
                'click': function() {
                    this.options.percentile95 = !this.options.percentile95;
                    if (!(this.options.percentiles)) {
                        this.options.percentiles = [];
                    }
                    if (this.options.percentile95) {
                        this.options.percentiles.push('95');
                        if ((this.chart) && (this.series[0].percentile95)) {
                            this.drawPercentiles(this.chart);
                        } else {
                            this.getData();
                        }
                        // tell liveToggler to be unchecked
                        if (this.options.live) {
                            this.liveToggler.fireEvent('click');
                        }
                        this.liveToggler.set('disabled', true);
                        // tell stackedToggler to be unchecked
                        if (this.options.stacked) {
                            this.stackedToggler.fireEvent('click');
                        }
                        this.stackedToggler.set('disabled', true);
                    } else {
                        // FIXME - when adding support for 5th and 50th percentiles
                        // etc we'll need to switch the options.percentiles array
                        // to a hash for easy enabling / disabling of percentiles
                        this.options.percentiles = [];
                        if (this.chart) {
                            this.removePercentiles(this.chart);
                        } else {
                            this.getData();
                        }
                        this.liveToggler.set('disabled', false);
                        this.stackedToggler.set('disabled', false);
                    }
                }.bind(this)
            },
            'styles': {
                'margin-right': '4px',
                'cursor': 'pointer'
            }
        });

        var percentile95Label = new Element('label', {
            'for': this.parentElement + '-percentile95',
            'html': '95th Percentile',
            'styles': {
                'font-family': 'sans-serif',
                'font-size':   '11px',
                'margin-right': '8px',
                'cursor': 'pointer'
            }
        });

        var stackedLabel = new Element('label', {
            'for': this.parentElement + '-stacked',
            'html': 'Stacked',
            'styles': {
                'font-family': 'sans-serif',
                'font-size': '11px',
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
        form.grab(percentile95Toggler)
        form.grab(percentile95Label)
        form.grab(liveToggler)
        form.grab(liveLabel)
        form.grab(stackedToggler)
        form.grab(stackedLabel)
        form.grab(select)
        container.grab(form, 'top')
    },
    setTimePeriodTo: function(selected) {
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

