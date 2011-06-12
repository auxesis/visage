var TokenSearchResult = new Class({
    Implements: [ Options, Events ],
    options: {
        'class': 'result',
        'events': {
            'mouseover': function(e) {
                var element       = e.target,
                    currentActive = element.getParent('ul').getElement('li.active');

                if (currentActive) {
                    currentActive.removeClass('active');
                }
                element.addClass('active');
            },
            'mouseout': function(e) {
                var element = e.target;
                element.removeClass('active');
            },
        }
    },
    initialize: function(options) {
        this.setOptions(options);
        this.element = new Element('li', this.options);
    },
    // http://mootools.net/blog/2010/03/19/a-better-way-to-use-elements/
    toElement: function() {
       return this.element;
    },
    active: function() {
        this.element.addClass('active');
    }

});


var TokenSearch = new Class({
    Implements: [ Options, Events ],
    initialize: function(element, dataSource) {
        this.tokenWrapper = $(element);
        this.tokens       = [];
        this.newToken();

        this.tokenWrapper.addEvent('click', function() {
            this.activeTokenInput().focus();
        }.bind(this));
    },
    activeToken: function() {
        return this.tokens.getLast();
    },
    activeTokenInput: function() {
        return this.tokens.getLast().getElement('input.token');
    },
    newToken: function() {
        token        = new Element("div",   { 'class': 'token' }),
        tokenInput   = new Element("input", { 'class': 'token', 'autocomplete': 'off' });

        token.grab(tokenInput);
        this.tokens.include(token)

        this.tokenWrapper.grab(token);
        tokenInput.focus();

        tokenInput.addEvent('keyup', function(e) {
            var reservedKeys = [ "down", "up", "enter",
                                 "pageup", "pagedown", "esc", "backspace" ];
            if (reservedKeys.contains(e.key)) { return };

            var input     = e.target,
                query     = input.get('value'),
                results   = this.data.filter(function(item) { return item.test(query, 'i') }),
                resultSet = this.tokenWrapper.getNext('ul.results');

            /* autocomplete */
            resultSet.empty();
            results.each(function(host, index) {
                var result = new TokenSearchResult({'html': host});
                if (index == 0) { result.active() };
                resultSet.grab(result);
            });
            if (results.length > 1) {
                var all = new TokenSearchResult({
                    'html': '&uarr; all of the above',
                    'class': 'result all',
                });
                resultSet.grab(all);
            }
        }.bind(this));

        tokenInput.addEvent('blur', function(e) {
                var tokenInput = this.activeTokenInput().get('value');

                /* Only delete the previous token if the active TokenInput is empty */
                if (tokenInput.length > 0) {
                    e.stop();
                    this.select();
                }
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
                    this.moveUp('top');
                    break;
                case "pagedown":
                    this.moveDown('bottom');
                    break;
                case "esc":
                    this.hideResults();
                    break;
                case "backspace":
                    this.destroyPreviousToken();
                    break;
                default:
                    console.log(e.key);
            }

        }.bind(this));

        return token;
    },
    destroyPreviousToken: function() {
        var tokenInput = this.activeTokenInput().get('value');

        /* Only delete the previous token if:
         *  - the active TokenInput is empty,
         *  - and was empty on the last keystroke.
         */
        if ((tokenInput.length == 0 && this.previousTokenInputLength > 0)
            || tokenInput.length > 0) {
            this.previousTokenInputLength = tokenInput.length;
            return
        } else {
            var token = this.tokens[this.tokens.length - 2];
            if (token) {
                this.tokens.erase(token);
                token.destroy()

                this.resizeWrapper();
            };
        }

    },
    hideResults: function() {
        var results = this.tokenWrapper.getNext('ul.results');
        results.empty();
    },
    select: function() {
        var results  = this.tokenWrapper.getNext('ul.results'),
            selected = results.getElement('li.active');

        if (selected.hasClass('all')) {
            var token = this.activeToken();
            this.tokens.erase(token);
            token.destroy();

            /* Create a token for each result. */
            results.getElements('li.result').each(function(result) {
                    if (result.hasClass('all')) { return };

                    var text  = result.get('html');
                    var token = this.newToken();
                    token.set('html', text);
                    token.addClass('finalized');
            }, this);
        } else {
            var token      = this.activeToken(),
                tokenInput = this.activeTokenInput(),
                text       = selected.get('html');

            tokenInput.destroy();
            token.set('html', text);
            token.addClass('finalized');
        }

        // IDEA: do selected.destroy() to remove just the entry?
        results.empty();

        this.newToken();

        this.resizeWrapper();
    },
    resizeWrapper: function() {
        var firstToken      = this.tokens[0],
            lastToken       = this.tokens[this.tokens.length - 1],
            lastTokenHeight = lastToken.getDimensions().height,
            baseY           = this.tokenWrapper.getPosition().y,
            minY            = firstToken.getPosition().y,
            maxY            = lastToken.getPosition().y;

        if (minY != maxY) {
            var newHeight = maxY - baseY + lastTokenHeight;
        } else {
            var newHeight = minY - baseY + lastTokenHeight;
        }
        this.tokenWrapper.setStyle('height', newHeight);
    },
    moveDown: function(position) {
        var active   = this.tokenWrapper.getNext('ul.results').getElement('li.active'),
            selected = this.tokenWrapper.getNext('ul.results');

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
        var active   = this.tokenWrapper.getNext('ul.results').getElement('li.active'),
            selected = this.tokenWrapper.getNext('ul.results');

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
});

var ChartBuilder = new Class({
    Implements: [ Options, Events ],
    initialize: function(element) {
        this.builder      = $(element);
        this.hostSearch   = this.builder.getElement("input#host-search");
        this.metricSearch = this.builder.getElement("input#metric-search");
        this.cacheHosts();

        this.setupHostSearch();
    },
    setupHostSearch: function() {
        var search = this.builder.getElement("div#hosts div.tokenWrapper"),
            data   = this.hosts;
        this.tokenSearch = new TokenSearch(search, data);

        /* events */
        this.metricSearch.addEvent('blur', function(e) {
            var input    = e.target,
                query    = input.get('value');
                selected = this.builder.getElement('div#hosts ul.results');

            if (query.test("^\s*$")) {
                selected.empty();
            }
        }.bind(this));

    },
    /*
    setupMetricSearch: function() {
        this.metricSearch.addEvent('focus', function(e) {
            var results = this.results;
            this.cacheMetrics(results)
        }.bind(this));

        this.metricSearch.addEvent('blur', function(e) {
            var input    = e.target,
                query    = input.get('value');
                selected = $$('div#metrics ul.results')[0];

            if (query.test("^\s*$")) {
                selected.empty();
            }
        }.bind(this));

        this.metricSearch.addEvent('keyup', function(e) {
            var input    = e.target,
                metrics  = this.metrics,
                query    = input.get('value');
                results  = metrics.filter(function(metric) { return metric.test(query, 'i') }),
                selected = $$('div#metrics ul.results')[0];

            this.results = results;

            selected.empty();
            results.each(function(metric) {
                var result = new Element('li', { 'html': metric });
                selected.grab(result);
            });

        }.bind(this));
    },
    */
    cacheHosts: function() {
        var request = new Request.JSONP({
            url:    "/data",
            method: "get",
            onComplete: function(json) {
                this.tokenSearch.data = json.hosts;
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
                this.metrics = json.metrics;
            }.bind(this)
        }).send();

        return
    }
});

window.addEvent('domready', function() {

    new ChartBuilder('chart-builder');

});

