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
        topGutter: 50,
        gridBorderColour: '#ccc',
        secureJSON: false,
        httpMethod: 'get'
    },
    initialize: function(element, host, plugin, options) {
        this.element = element;
        this.setOptions(options);
        this.options.host = host;
        this.options.plugin = plugin;
        this.canvas = Raphael(element, this.options.width, this.options.height);
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
            secure: this.options.secureJSON,
            method: this.options.httpMethod,
            onComplete: function(json) {
                this.graphData(json);
            }.bind(this),
            onFailure: function(header, value) {
                $(this.element).set('html', header)
            }.bind(this)
        });

        this.request.send();
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
    // assemble data to graph, then draw it
    graphData: function(data) {

        this.y = []
        this.colors = []
        this.pluginInstanceNames = []

        $each(data[this.options.host][this.options.plugin], function(pluginInstance, pluginInstanceName) {
            startTime = pluginInstance.splice(0,1)
            endTime = pluginInstance.splice(0,1)
            dataSources = pluginInstance.splice(0,1)
            dataSets = pluginInstance.splice(0,1)
        
            this.pluginInstanceNames.push(pluginInstanceName)

            // color names are not structured consistently - extract them
            colors = pluginInstance.splice(0,1)
            this.populateColors(colors);

            axes = this.extractYAxes(dataSources, dataSets)
            // sometimes we have multiple datapoints in a dataset (eg load/load)
            axes.each(function(axis) { this.y.push(axis) }, this);
        }, this);

      
        this.canvas.g.txtattr.font = "11px 'sans-serif'";

        x = [];
        for (var i = 0; i < this.y[0].length; i++) {
            x.push(i)
        }

        this.graph = this.canvas.g.linechart(this.options.leftEdge, this.options.topEdge, this.options.gridWidth, this.options.gridHeight, x, this.y, {
                            nostroke: false, 
                            shade: false, 
                            width: 1.5,
                            axis: "0 0 1 1", 
                            colors: this.colors, 
                            axisxstep: x.length / 20
        });

        this.graphLines = [];
        $each(this.graph.items[1].items, function(line) { this.graphLines.push(line) }, this);

        this.buildLabels(this.graphLines, this.pluginInstanceNames, this.colors);
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
            
            var container = $(this.element).getNext('div.timescale.container');
            var form = new Element('form', { 
                    'action': this.dataURL(), 
                    'method': 'get',
                    'events': {
                        'submit': function(e) {
                            e.stop();
                            this.getData();
                        }.bind(this)
                    }
            });

            var select = new Element('select', { 'class': 'date timescale' });
            var hours = [1, 2, 6, 12, 24, 48, 72, 168, 672]
            hours.each(function(hour) {
                var option = new Element('option', {
                    html: 'last {hour} hours'.substitute({'hour': hour }),
                    value: "starttime={starttime}".substitute({'starttime': currentUnixTime - (hour * 3600)})
                });
                select.grab(option)
            });
            
            var submit = new Element('input', { 'type': 'submit', 'value': 'show' });
            
            form.grab(select);
            form.grab(submit);
            container.grab(form);
    },
    buildLabels: function(graphLines, instanceNames, colors) {
        
        instanceNames.each(function(instanceName, index) {
            var path = graphLines[index];
            var color = colors[index]
            var name = instanceName.split('-')[1]

            var container = new Element('div', {
                'class': 'label plugin',
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

            var box = new Element('span', {
                'class': 'label plugin box ' + instanceName,
                'html': '&nbsp;',
                'styles': { 
                      'background-color': color
                }
            });
        
            var desc = new Element('span', {
                'class': 'label plugin description ' + instanceName,
                'html': name
            });
       
            container.grab(box);
            container.grab(desc);
            $(this.element).getNext('div.labels').grab(container);

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

