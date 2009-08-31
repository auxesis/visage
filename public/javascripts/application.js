window.addEvent('domready', function () {

  var graphData = function(data) {
    var host = 'theodor';
    var plugin = 'load';
    var plugin_instance = 'load';
    var stats = data[host][plugin][plugin_instance];

    var startTime = stats.splice(0,1);
    var endTime = stats.splice(0,1);
    var labels = stats.splice(0,1)[0];
    var dataSet = stats.splice(0,1);
 
    organisedDataSet = new Hash();
    labels.each(function(label, index) {
      blob = new Hash();
      blob.set('data', dataSet[0].map(function(item) { 
          return isNaN(item[index]) ? 0 : item[index] 
      }));
      blob.set('path', r.path({"stroke": colours[plugin][plugin_instance][label] || "#000", 
                               "stroke-width": 1.5}));

      blob.set('min', Math.min.apply(Math, blob.get('data')));
      blob.set('max', Math.max.apply(Math, blob.get('data')));
      organisedDataSet.set(label, blob);
    });

    var length = organisedDataSet.get(labels[0]).get('data').length;

    var minX = leftEdge;
    var maxX = leftEdge / 4 + gridWidth;
    var minY = topEdge + gridHeight;
    var maxY = topEdge;

    organisedDataSet.each(function(blob, key) {
      blob['data'].each(function(value, index) {
        x = minX + index / length * maxX;
        y = minY - value * maxY * maxY;
        blob['path'][index == 0 ? "moveTo" : "cplineTo"](x, y);
      });
    });

    labels.each(function(label) {
        container = new Element('div', {
                  'class': 'label plugin',
                  'events': {
                      'mouseover': function(e) {
                         e.stop();
                         var path = organisedDataSet.get(label).get('path');
                         path.animate({'stroke-width': 3}, 300);
                      },
                      'mouseout': function(e) {
                         e.stop();
                         var path = organisedDataSet.get(label).get('path');
                         path.animate({'stroke-width': 1.5}, 300);
                      },
                      'click': function(e) {
                         e.stop();
                         var path = organisedDataSet.get(label).get('path');
                         path.animate({'opacity': 0.5}, 500);
                      }
                  }
        });

        box = new Element('span', {
            'class': 'label plugin box ' + label,
            'html': '&nbsp;',
            'styles': { 
              'background-color': colours[plugin][plugin_instance][label]
            }
        });

        desc = new Element('span', {
            'class': 'label plugin description ' + label,
            'html': label
        });

        container.grab(box);
        container.grab(desc);
        $('labels').grab(container);
    });

  };

  var colours = {'load': {'load': {'shortterm': "#73d216", 
                                   'midterm': "#3465a4",
                                   'longterm': "#ef2929"}},
                 'memory': {'memory-free': {'value': '#75507b'}}
  }

  var request = new Request.JSON({
    url: '/data/theodor/load/load',
    secure: false,
    onComplete: function(responseJSON, responseText) {
      graphData(responseJSON);
    }
  });

  var width = 900, 
      height = 480,
      leftEdge = 10,
      topEdge = 10,
      gridWidth = 670,
      gridHeight = 200,
      columns = 60,
      rows = 8,
      topGutter = 50,
      gridBorderColour = '#ccc';

  var r = Raphael("holder", width, height);

  r.drawGrid(
      leftEdge, 
      topEdge, 
      gridWidth, 
      gridHeight,
      columns, 
      rows, 
      gridBorderColour
  );

  var time = (new Date).getTime() / 1000;
  request.get({'start': time - 3600 , 'end': time});
  
});

