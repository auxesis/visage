var collectdSingleGraph = new Class({
    Implements: [Options, Events],
    options: {
  			host: 'theodor',
	  		plugin: 'load',
        plugin_instance: 'load',
				width: 900,
				height: 220,
				leftEdge: 10,
				topEdge: 10,
				gridWidth: 670,
				gridHeight: 200,
				columns: 60,
				rows: 8,
				topGutter: 50,
				gridBorderColour: '#ccc',
				secureJSON: false,
				colours: {'load': {'load': {'shortterm': "#73d216",                                  
				                            'midterm': "#3465a4",                                    
								                    'longterm': "#ef2929"}},                                 
					        'memory': {'memory-free': {'value': '#75507b'}},
									'cpu-0': {'cpu-idle': {'value': '#ef2929'},
														'cpu-wait': {'value': '#edd400'}}
				  			 }
				
    },
		stats: {},
    initialize: function(element, options) {
				this.element = element;
        this.setOptions(options);
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
		data: ['hello'],
		graphData: function(data) {

	    this.stats = data[this.options.host][this.options.plugin][this.options.plugin_instance];
      this.startTime = this.stats.splice(0,1);
      this.endTime = this.stats.splice(0,1);
      this.labels = this.stats.splice(0,1)[0];
      this.dataSet = this.stats.splice(0,1);

			this.structuredDataSet = new Hash()
			this.labels.each(function(label, index) {
					blob = new Hash()
					blob.set('data', this.dataSet[0].map(function(item) {
							return isNaN(item[index]) ? 0 : item[index]
					}));
					blob.set('min', Math.min.apply(Math, blob.get('data')));                              
					blob.set('max', Math.max.apply(Math, blob.get('data')));                              
					blob.set('colour', this.options.colours[this.options.plugin][this.options.plugin_instance][label]);
					this.structuredDataSet.set(label, blob);
			}, this);
			
			length = this.structuredDataSet.get(this.labels[0]).get('data').length

      var x = [];
      for (var i = 0; i < length; i++) {
          x[i] = i * this.options.gridWidth / length;
      }

			y = []
			colours = []
			this.structuredDataSet.each(function(value, key) { 
					y.include(value.get('data'));  
					colours.include(value.get('colour'));
			});

      this.canvas.g.txtattr.font = "11px 'sans-serif'";
      this.canvas.g.linechart(20, 10, this.options.gridWidth, this.options.gridHeight, x, y, {
          nostroke: false, shade: false, width: 1.5,
          axis: "0 0 1 1", axisxlabels: 'head', axisxstep: 10,
					colors: colours
      });

			this.buildLabels(this.labels)
		},
		buildLabels: function(labels) {
		    labels.each(function(label) {
        		container = new Element('div', {
        				'class': 'label plugin',
            });

		        box = new Element('span', {
		            'class': 'label plugin box ' + label,
		            'html': '&nbsp;',
		            'styles': { 
		              'background-color': this.options.colours[this.options.plugin][this.options.plugin_instance][label]
		            }
		        });
		
		        desc = new Element('span', {
		            'class': 'label plugin description ' + label,
		            'html': label
		        });
		
		        container.grab(box);
		        container.grab(desc);
		        $(this.element).getChildren('div.labels')[0].grab(container);

    		},this);	
		}

});
