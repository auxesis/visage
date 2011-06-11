var ChartBuilder = new Class({
    Implements: [ Options, Events ],
    initialize: function(element) {
        this.builder      = $(element);
        this.hostSearch   = this.builder.getElement("input#host-search");
        this.metricSearch = this.builder.getElement("input#metric-search");
        this.cacheHosts();

        this.setupHostSearch();
        this.setupMetricSearch();
    },
    setupHostSearch: function() {
        var tokenWrapper = this.builder.getElement("div#hosts div.tokenWrapper"),
            token        = new Element("span",  { 'class': 'token' }),
            tokenInput   = new Element("input", { 'class': 'token', 'autocomplete': 'off' });

        token.grab(tokenInput);
        tokenWrapper.grab(token);

        this.tokenWrapper = tokenWrapper;

        /* events */
        this.metricSearch.addEvent('blur', function(e) {
            var input    = e.target,
                query    = input.get('value');
                selected = this.builder.getElement('div#hosts ul.selected');

            if (query.test("^\s*$")) {
                selected.empty();
            }
        }.bind(this));

        tokenInput.addEvent('keyup', function(e) {
            if (["down", "up", "enter"].contains(e.key)) { return };

            var input    = e.target,
                hosts    = this.hosts.hosts,
                query    = input.get('value'),
                results  = hosts.filter(function(host) { return host.test(query, 'i') }),
                selected = this.builder.getElement('div#hosts ul.selected');

            this.results = results;

            /* autocomplete */
            selected.empty();
            results.each(function(host, index) {
                var result = new Element('li', { 'html': host, 'class': 'result' });
                if (index == 0) { result.addClass('active') };
                selected.grab(result);
            });
            var all = new Element('li', {'html': '&uarr; all of the above', 'class': 'result all'});
            selected.grab(all);
        }.bind(this));

        /* autocomplete menu navigation */
        tokenInput.addEvent('keyup', function(e) {
            switch(e.key) {
                case "down":
                    this.moveDown();
                    break;
                case "up":
                    this.moveUp();
                    break;
                case "enter":
                    this.select();
                    break;
                case "pageup":
                    this.moveUp('top')
                    break
                case "pagedown":
                    this.moveDown('bottom')
                    break
            }

        }.bind(this));
    },
    select: function() {
        var active     = this.builder.getElement('div#hosts li.active'),
            token      = this.tokenWrapper.getElement('span.token'),
            tokenInput = this.tokenWrapper.getElement('input.token'),
            selected   = this.builder.getElement('div#hosts ul.selected'),
            text       = active.get('html');

        tokenInput.destroy();
        if (text.test("all of the above")) {
            text = selected.getElement('li').get('html');
            token.set('html', text);
            token.addClass('finalized');
        } else {
            token.set('html', text);
            token.addClass('finalized');
        }
        selected.empty();
    },
    moveDown: function(position) {
        var active   = this.builder.getElement('div#hosts li.active'),
            selected = this.builder.getElement('div#hosts ul.selected');

        if (position == "bottom") {
            down = selected.getLast('li.result');
        } else {
            down = active.getNext('li.result');
        }

        if (down) {
            active.toggleClass('active');
            down.toggleClass('active');
        }
    },
    moveUp: function(position) {
        var active   = this.builder.getElement('div#hosts li.active'),
            selected = this.builder.getElement('div#hosts ul.selected');

        if (position == "top") {
            up = selected.getFirst('li.result');
        } else {
            up = active.getPrevious('li.result');
        }

        if (up) {
            active.toggleClass('active');
            up.toggleClass('active');
        }
    },
    setupMetricSearch: function() {
        this.metricSearch.addEvent('focus', function(e) {
            var results = this.results;
            this.cacheMetrics(results)
        }.bind(this));

        this.metricSearch.addEvent('blur', function(e) {
            var input    = e.target,
                query    = input.get('value');
                selected = $$('div#metrics ul.selected')[0];

            if (query.test("^\s*$")) {
                selected.empty();
            }
        }.bind(this));

        this.metricSearch.addEvent('keyup', function(e) {
            var input    = e.target,
                metrics  = this.metrics.metrics,
                query    = input.get('value');
                results  = metrics.filter(function(metric) { return metric.test(query, 'i') }),
                selected = $$('div#metrics ul.selected')[0];

            this.results = results;

            selected.empty();
            results.each(function(metric) {
                var result = new Element('li', { 'html': metric });
                selected.grab(result);
            });

        }.bind(this));
    },
    cacheHosts: function() {
        var request = new Request.JSONP({
            url:    "/data",
            method: "get",
            onComplete: function(json) {
                this.hosts = json;
            }.bind(this)
        }).send();

        return
    },
    cacheMetrics: function(hosts) {
        var url     = "/data/" + hosts.join(',');
        var request = new Request.JSONP({
            url:    url,
            method: "get",
            onComplete: function(json) {
                this.metrics = json;
            }.bind(this)
        }).send();

        return
    }
});

window.addEvent('domready', function() {

    new ChartBuilder('chart-builder');

});

