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
            secureJSON: false
    },
    initialize: function(element, host, plugin, options) {
        this.element = element;
        this.setOptions(options);
        this.options.host = host;
        this.options.plugin = plugin;
        this.canvas = Raphael(element, this.options.width, this.options.height);
        this.getData(); // calls graphData
    },
    getData: function() {
        this.request = new Request.JSON({
            url: ['/data', this.options.host, this.options.plugin, this.options.plugin_instance].join('/'),
            secure: this.options.secureJSON,
            onComplete: function(json) {
                this.graphData(json);
            }.bind(this),
            onFailure: function(header, value) {
                $(this.element).set('html', header)
            }.bind(this)
        });

        this.request.get();
    },
});

/* 
 * collectdMultiGraph()
 *
 * Original graph implementation. Superseded by visageGraph().
 *
 */
var collectdMultiGraph = new Class({
    Extends: visageBase,
    graphData: function(data) {

        this.plugin_instances = new Hash()

        $each(data[this.options.host][this.options.plugin], function(data, plugin_instance) {

            stats = data;
            startTime = stats.splice(0,1);
            endTime = stats.splice(0,1);
            labels = stats.splice(0,1)[0];
            dataSet = stats.splice(0,1);

            structuredDataSet = new Hash()
            labels.each(function(label, index) {
                blob = new Hash()
                blob.set('data', dataSet[0].map(function(item) {
                    return isNaN(item[index]) ? 0 : item[index]
                }));
                blob.set('min', Math.min.apply(Math, blob.get('data')));                              
                blob.set('max', Math.max.apply(Math, blob.get('data')));
                blob.set('colour', this.options.colours[this.options.plugin][plugin_instance][label]);
                structuredDataSet.set(label, blob);
            }, this);

            this.plugin_instances.set(plugin_instance, structuredDataSet);
						this.startTime = startTime;
						this.endTime = endTime;
            this.length = structuredDataSet.value.get('data').length
               
        }, this);

        var x = [];
        for (var i = 0; i < this.length; i++) {
            x[i] = i * (this.endTime - this.startTime) / this.length / 60;
        }

				x.reverse();

        y = []
        colours = []
        this.plugin_instances.each(function(data, name) {
            y.include(data.value.get('data'));
            colours.include(data.value.get('colour'));
        })
        
        this.canvas.g.txtattr.font = "11px 'sans-serif'";
        c = this.canvas.g.linechart(this.options.leftEdge, this.options.topEdge, this.options.gridWidth, this.options.gridHeight, x, y, {
            nostroke: false, shade: false, width: 1.5,
            axis: "0 0 1 1", axisxlabels: 'head', axisxstep: 10,
            colors: colours
        });

        lines = c.items[1]
        count = 0
        this.plugin_instances.each(function(data, name) {
            data.set('line', lines[count])
            count += 1
        })
  
        this.buildLabels(this.plugin_instances)
    },
    buildLabels: function(plugin_instances, lines) {
        plugin_instances.each(function(data, name) {
            container = new Element('div', {
                'class': 'label plugin',
                'events': {
                    'mouseover': function(e) {
                        e.stop();
                        var path = data.get('line');
                        path.animate({'stroke-width': 3}, 300);
                        //path.toFront();
                    },
                    'mouseout': function(e) {
                        e.stop();
                        var path = data.get('line');
                        path.animate({'stroke-width': 1.5}, 300);
                        //path.toBack();
                    },
										'click': function(e) {
												e.stop();
                        var path = data.get('line');
												path.attr('opacity') == 0 ? path.animate({'opacity': 1}, 350) : path.animate({'opacity': 0}, 350);
										}
                }
            });

            box = new Element('span', {
                'class': 'label plugin box ' + name,
                'html': '&nbsp;',
                'styles': { 
                      'background-color': data.value.get('colour')
                }
            });
        
            desc = new Element('span', {
                'class': 'label plugin description ' + name,
                'html': name.split('-')[1]
            });
        
            container.grab(box);
            container.grab(desc);
            $(this.element).getChildren('div.labels')[0].grab(container);

        },this);    
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

