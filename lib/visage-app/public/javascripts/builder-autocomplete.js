var SearchToken = new Class({
    Implements: [ Options, Events ],
    initialize: function(wrapper, options) {
        this.wrapper = wrapper;
        this.setOptions(options);
        this.element = new Element("div",   { 'class': 'token' });
        this.input   = new Element("input", { 'class': 'token', 'autocomplete': 'off' });

        this.element.grab(this.input);
        this.options.data.pass(null,this)();

        this.setupInputEvents();
    },
    value: function() {
        return this.element.get('text')
    },
    setupInputEvents: function() {
        /* Autocomplete menu */
        this.input.addEvent('keyup', function(e) {
            /* These keys are trigger actions on the autocomplete menu. */
            var reservedKeys = [ "down", "up", "enter",
                                 "pageup", "pagedown",
                                 "esc", "backspace" ];
            if (reservedKeys.contains(e.key)) { return };

            var input     = e.target,
                query     = input.get('value'),
                resultSet = this.resultSet(),
                data      = this.data,
                existing  = this.wrapper.tokens.map(function(token) { return token.value() }),
                results   = data.filter(function(item) {
                    return (item.test(query, 'i') && !existing.contains(item) )
                });

            /* Build the result set to display */
            resultSet.empty();
            results.each(function(host, index) {
                var result = new TokenSearchResult({'html': host});
                if (index == 0) { result.active() };
                resultSet.grab(result);
            });
            /* Catchall entry */
            if (results.length > 1) {
                var all = new TokenSearchResult({
                    'html': '&uarr; all of the above',
                    'class': 'result all',
                });
                resultSet.grab(all);
            }
        }.bind(this));

        /* Tab == enter for autocomplete */
        this.input.addEvent('blur', function(e) {
                var input = e.target.get('value');
                if (input.length > 0) {
                    e.stop();
                    this.select();
                }
        }.bind(this));

        /* Autocomplete menu navigation */
        this.input.addEvent('keyup', function(e) {
            switch(e.key) {
                case "down":
                    this.down();
                    break;
                case "up":
                    this.up();
                    break;
                case "enter":
                    this.select();
                    break;
                case "pageup":
                    this.up('top');
                    break;
                case "pagedown":
                    this.down('bottom');
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

    },
    toElement: function() {
       return this.element;
    },
    finalize: function() {
    },
    takeFocus: function() {
        this.input.focus();
    },
    resultSet: function() {
        return this.element.getParent('div.search').getElement('ul.results');
    },
    getActive: function() {
        return this.resultSet().getElement('li.active');
    },
    down: function(position) {
        var resultSet = this.resultSet();
            active    = this.getActive();

        if (position == "bottom") {
            down = resultSet.getLast('li.result');
        } else {
            down = active.getNext('li.result');
        }

        if (down) {
            active.toggleClass('active');
            down.toggleClass('active');
        }
    },
    up: function(position) {
        var resultSet = this.resultSet(),
            active    = this.getActive();

        if (position == "top") {
            up = resultSet.getFirst('li.result');
        } else {
            up = active.getPrevious('li.result');
        }

        if (up) {
            active.toggleClass('active');
            up.toggleClass('active');
        }
    },
    destroyPreviousToken: function() {
        var input = this.input.get('value');

        /* Only delete the previous token if:
         *  - the active TokenInput is empty,
         *  - and was empty on the last keystroke.
         */
        if ((input.length == 0 && this.previousInputLength > 0)
            || input.length > 0) {
            this.previousInputLength = input.length;
            return
        } else {
            var token = this.wrapper.tokens[this.wrapper.tokens.length - 2];
            if (token) {
                this.wrapper.destroyToken(token);
                this.wrapper.resize();
            };
        }

    },
    hideResults: function() {
        var results = this.resultSet();
        results.empty();
    },
    select: function() {
        var resultSet  = this.resultSet(),
            selected   = this.getActive();

        if (selected.hasClass('all')) {
            var token = this;
            this.wrapper.destroyToken(token);

            /* Create a token for each result. */
            resultSet.getElements('li.result').each(function(result) {
                    if (result.hasClass('all')) { return };

                    var text  = result.get('html');
                    var token = $(this.wrapper.newToken());
                    token.set('html', text);
                    token.addClass('finalized');
            }, this);
        } else {
            var token = this.element,
                input = this.input,
                text  = selected.get('html');

            input.destroy();
            token.set('html', text);
            token.addClass('finalized');
        }

        // IDEA: do selected.destroy() to remove just the entry?
        resultSet.empty();

        this.wrapper.newToken();

        this.wrapper.resize();
    },
});

var TokenSearchResult = new Class({
    Implements: [ Options, Events ],
    options: {
        'class': 'result',
        'events': {
            'mouseenter': function(e) {
                var element       = e.target,
                    currentActive = element.getParent('ul').getElement('li.active');

                if (currentActive) {
                    currentActive.removeClass('active');
                }
                element.addClass('active');
            },
            'mouseleave': function(e) {
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
    initialize: function(parent, options) {
        this.setOptions(options);
        this.parent  = $(parent);
        this.element = new Element('div', {'class': 'tokenWrapper'})
        this.results = new Element('ul',  {'class': 'results'})
        this.parent.grab(this.element);
        this.parent.grab(this.results);
        this.tokens  = [];
        this.newToken();

        /* Clicks within the contain focus input on the editable token. */
        this.element.addEvent('click', function() {
            this.tokens.getLast().takeFocus();
        }.bind(this));
    },
    newToken: function() {
        var token = new SearchToken(this, {'data': this.options.data});

        this.tokens.include(token);
        this.element.grab(token);
        token.takeFocus();

        return token;
    },
    destroyToken: function(token) {
        this.tokens.erase(token);
        $(token).destroy()
    },
    resize: function() {
        var firstToken      = $(this.tokens[0]),
            lastToken       = $(this.tokens[this.tokens.length - 1]),
            lastTokenHeight = lastToken.getDimensions().height,
            baseY           = this.element.getPosition().y,
            minY            = firstToken.getPosition().y,
            maxY            = lastToken.getPosition().y;

        if (minY != maxY) {
            var newHeight = maxY - baseY + lastTokenHeight;
        } else {
            var newHeight = minY - baseY + lastTokenHeight;
        }
        this.element.setStyle('height', newHeight);
    },
});

var ChartBuilder = new Class({
    Implements: [ Options, Events ],
    initialize: function(element) {
        this.builder = $(element);
        this.setupHostSearch();
    },
    setupHostSearch: function() {
        var search = this.builder.getElement("div#hosts div.search");
        this.tokenSearch = new TokenSearch(search, { 'data': this.getHosts });
    },

        /* events */
    /*
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
    getHosts: function() {
        var request = new Request.JSONP({
            url:    "/data",
            method: "get",
            onComplete: function(json) {
                this.data = json.hosts;
            }.bind(this)
        }).send();

        return request;
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

