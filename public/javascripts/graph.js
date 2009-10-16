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
        leftEdge: 100,
        topEdge: 10,
        gridWidth: 670,
        gridHeight: 200,
        columns: 60,
        rows: 8,
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
        this.buildGraphHeader();
        this.buildGraphContainer();
        this.canvas = Raphael(this.graphContainer, this.options.width, this.options.height);
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
    buildGraphHeader: function() {
        header = $chk(this.options.name) ? this.options.name : this.options.plugin
        this.graphHeader = new Element('h3', {
            'class': 'graph-title',
            'html': header
        });
        $(this.parentElement).grab(this.graphHeader);
    },
    buildGraphContainer: function() {
        $(this.parentElement).set('style', 'padding-top: 1em');

        this.graphContainer = new Element('div', {
            'class': 'graph container',
            'styles': {
                'margin-bottom': '24px'
            }
        });
        $(this.parentElement).grab(this.graphContainer)
    }
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

        this.buildContainers();

        this.y = []
        this.colors = []
        this.pluginInstanceNames = []
        this.pluginInstanceDataSources = []
        this.intervals = new Hash()

        $each(data[this.options.host][this.options.plugin], function(pluginInstance, pluginInstanceName) {
            startTime = pluginInstance.splice(0,1)
            endTime = pluginInstance.splice(0,1)
            dataSources = pluginInstance.splice(0,1)
            dataSets = pluginInstance.splice(0,1)
       
            this.intervals.set('start', startTime);
            this.intervals.set('end', endTime);
            this.pluginInstanceNames.push(pluginInstanceName)
            this.populateDataSources(dataSources);

            // color names are not structured consistently - extract them
            colors = pluginInstance.splice(0,10)
            this.populateColors(colors);

            axes = this.extractYAxes(dataSources, dataSets)
            // sometimes we have multiple datapoints in a dataset (eg load/load)
            axes.each(function(axis) { this.y.push(axis) }, this);
        }, this);

      
        this.canvas.g.txtattr.font = "11px 'sans-serif'";

        var start = this.intervals.get('start')[0]
        var end = this.intervals.get('end')[0]
        var increment = (end - start) / this.y[0].length;

        x = [];

        var counter = start;
        while (counter < end) {
            x.push(counter)
            counter += increment
        }

        this.graph = this.canvas.g.linechart(this.options.leftEdge, this.options.topEdge, this.options.gridWidth, this.options.gridHeight, x, this.y, {
                            nostroke: false, 
                            shade: false, 
                            width: 1.5,
                            axis: "0 0 1 1", 
                            colors: this.colors, 
                            axisxstep: x.length / 20,
                            shade: this.options.shade
        });

        this.formatAxes();
        this.addSelectionInterface();

        this.buildLabels(this.graph.lines, this.pluginInstanceNames, this.pluginInstanceDataSources, this.colors);
        this.buildDateSelector();

        /* disabling this for now for dramatic effect
        this.buildEmbedder();
        */
    },
    formatAxes: function() {

        /* clean up graph labels */
        this.graph.axis[0].text.items.getLast().hide()
        $each(this.graph.axis[0].text.items, function (time) {
            
            var unixTime = time.attr('text')
            var d = new Date(time.attr('text') * 1000);
            time.attr({'text': d.strftime("%H:%M")});

            time.mouseover(function () {
                this.attr({'text': d.strftime("%H:%M")});
            });

            /*
            time.mouseout(function () {
                this.attr({'text': d.strftime("%H:%M")});
            });
            */
        });

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

    },
    buildEmbedder: function() {
        var pre = new Element('textarea', {
                'id': 'embedder',
                'class': 'embedder',
                'html': this.embedCode(),
                'styles': {
                    'width': '500px',
                    'padding': '3px'
                }
        });
        this.embedderContainer.grab(pre);

        var slider = new Fx.Slide(pre, {
            duration: 200 
        });

        slider.hide();

        var toggler = new Element('a', {
                'id': 'toggler',
                'class': 'toggler',
                'html': '(embed)',
                'href': '#',
                'styles': {
                    'font-size': '0.7em',
                }
        });
        toggler.addEvent('click', function(e) {
            e.stop();
            slider.toggle();
        });
        this.embedderTogglerContainer.grab(toggler);
    },
    embedCode: function() {
        baseurl = "{protocol}//{host}".substitute({'host': window.location.host, 'protocol': window.location.protocol});
        code = "<script src='{baseurl}/javascripts/visage.js' type='text/javascript'></script>".substitute({'baseurl': baseurl});
        code += "<div id='graph'></div>"
        code += "<script type='text/javascript'>window.addEvent('domready', function() { var graph = new visageGraph('graph', '{host}', '{plugin}', ".substitute({'host': this.options.host, 'plugin': this.options.plugin});
        code += "{"
        code += "width: 900, height: 220, gridWidth: 800, gridHeight: 200, baseurl: '{baseurl}'".substitute({'baseurl': baseurl});
        code += "}); });</script>"
        return code.replace('<', '&lt;').replace('>', '&gt;')
    },
    addSelectionInterface: function() {
        var graph = this.graph;
        var parentElement = this.parentElement
        var gridHeight = this.options.gridHeight
        graph.selectionMade = true
        this.graph.clickColumn(function () {
            if ($chk(graph.selectionMade) && graph.selectionMade) {
                if ($defined(graph.selection)) {
                    graph.selection.remove();
                }
                graph.selectionMade = false
                graph.selection = this.paper.rect(this.x, 0, 1, gridHeight);
                graph.selection.toBack();
                graph.selection.attr({'fill': '#000'});
                graph.selectionStart = this.axis
            } else {
                graph.selectionMade = true
                graph.selectionEnd = this.axis
                var select = $(parentElement).getElement('div.timescale.container select')
                var hasSelected = select.getChildren('option').some(function(option) {
                    return option.get('html') == 'selected'
                });
                if (!hasSelected) {
	                var option = new Element('option', {
	                    html: 'selected',
	                    value: '',
	                    selected: true
	                });
	                select.grab(option)
                }
            }
        });
        this.graph.hoverColumn(function () {
            if ($chk(graph.selection) && !graph.selectionMade) {
                var width = this.x - graph.selection.attr('x');
                graph.selection.attr({'width': width});
            }
        });

    },
    buildContainers: function() {
        this.embedderTogglerContainer = new Element('div', {
            'class': 'embedder-toggler container',
            'styles': {
                'float': 'right',
                'width': '20%',
                'text-align': 'right',
                'margin-right': '12px',
                'padding-top': '4px'
            }
        });
        $(this.parentElement).grab(this.embedderTogglerContainer, 'top')

        this.timescaleContainer = new Element('div', {
            'class': 'timescale container',
            'styles': {
                'float': 'right',
                'width': '20%'
            }
        });
        $(this.parentElement).grab(this.timescaleContainer, 'top')
        
        this.labelsContainer = new Element('div', {
            'class': 'labels container',
            'title': 'click to hide',
            'styles': {
                'float': 'left',
                'margin-left': '80px',
                'padding-bottom': '1em'
            }
        });
        $(this.parentElement).grab(this.labelsContainer)
        
        this.embedderContainer = new Element('div', {
            'class': 'embedder container',
            'styles': {
                'font-style': 'monospace',
                'margin-left': '80px',
                'font-size': '0.8em',
                'clear': 'both'
            }
        });
        $(this.parentElement).grab(this.embedderContainer)
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
            
            var container = $(this.timescaleContainer);
            var form = new Element('form', { 
                    'action': this.dataURL(), 
                    'method': 'get',
                    'events': {
                        'submit': function(e, foo) {
                            e.stop();
                          
                            /*
                             * Get the selected option, turn it into a hash for 
                             * getData() to use.
                             */
                            data = new Hash()
                            if (e.target.getElement('select').getSelected().get('html') == 'selected') {
                                data.set('start', this.graph.selectionStart);
                                data.set('end', this.graph.selectionEnd);
                            } else {
	                            e.target.getElement('select').getSelected().each(function(option) {
	                                split = option.value.split('=')
	                                data.set(split[0], split[1])
	                                currentTimePeriod = option.get('html') // is this setting a global?
	                            }, this);
                            }
                            this.requestData = data

                            /* Nuke graph + labels. */
                            this.graph.remove();
                            $(this.labelsContainer).empty();
                            $(this.timescaleContainer).empty();
                            $(this.embedderContainer).empty();
                            $(this.embedderTogglerContainer).empty();
                            if ($defined(this.graph.selection)) {
                                this.graph.selection.remove();
                            }
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
            
            form.grab(select);
            form.grab(submit);
            container.grab(form);
    },
    buildLabels: function(graphLines, instanceNames, dataSources, colors) {

        dataSources.each(function(ds, index) {
            var path = graphLines[index];
            var color = colors[index]
            
            var instanceName = instanceNames[index]

            // generic ds name, attempt to specialise
            if (ds == 'value') {
                if (instanceName.match(/-/)) {
                    var name = instanceName.split('-')[1]
                } else {
                    var name = instanceName
                }
            // disk operations
            } else if (ds == 'read' || ds == 'write') {
                var instanceName = instanceNames[Math.round((index -1) / 2)]
                var name = instanceName.split('_')[1] + '-' + ds
            } else {
                var name = ds
            }

            var container = new Element('div', {
                'class': 'label plugin',
                'styles': {
                    'padding': '0.2em 0.5em 0',
                    'float': 'left',
                    'width': '180px',
                    'font-size': '0.8em'
                },
                'events': {
                    'mouseover': function(e) {
                        e.stop();
                        path.animate({'stroke-width': 3}, 300);
                        //path.toFront();
                    },
                    'mouseout': function(e) {
                        e.stop();
                        path.animate({'stroke-width': 1.5}, 300);
                        //path.toBack();
                    },
                    'click': function(e) {
                        e.stop();
                        path.attr('opacity') == 0 ? path.animate({'opacity': 1}, 350) : path.animate({'opacity': 0}, 350);
                    }
                }
            });

            var box = new Element('div', {
                'class': 'label plugin box ' + instanceName,
                'html': '&nbsp;',
                'styles': { 
                      'background-color': color,
                      'width': '48px',
                      'height': '18px',
                      'float': 'left',
                      'margin-right': '0.5em'
                }
            });
        
            var desc = new Element('span', {
                'class': 'label plugin description ' + instanceName,
                'html': name
            });

            container.grab(box);
            container.grab(desc);
            $(this.labelsContainer).grab(container);

        }, this);
    },
    /* recurse through colours data structure and generate a list of colours */
    populateColors: function(nestedColors) {
            switch($type(nestedColors)) {
                case 'array':
                    nestedColors.each(function(c) {
                        this.populateColors(c);
                    }, this);
                    break
                case 'string':
                    this.colors.push(nestedColors);
                    break
                default: 
                    $each(nestedColors, function(c) {
                        this.populateColors(c)
                    }, this);
            }
    },
    /* recurses, normalised data sources */
    populateDataSources: function (dataSources) {
        switch($type(dataSources)) {
            case 'array': 
                dataSources.each(function(ds) {
                    this.populateDataSources(ds)
                }, this);
                break
            case 'string': 
                this.pluginInstanceDataSources.push(dataSources);
                break
            default: 
                $each(dataSources, function(ds) {
                    this.populateDataSources(ds)
                }, this);
        }
    },
    // separates the datasets into separate y-axes, suitable for passing to g.raphael 
    extractYAxes: function(dataSources, dataSets) {
        y = []
        dataSources[0].length.times(function() { y.push([]) });

        dataSets[0].each(function(primaryDataPoints) {
            primaryDataPoints.each(function(pdp, index) {
                // the last few pdps tend to be NaNs. normalise
                value = isNaN(pdp) ? 0 : pdp
                y[index].push(value)
            });
        });

        return y
    }
})

