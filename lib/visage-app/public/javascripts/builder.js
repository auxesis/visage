var SearchToken = new Class({
    Implements: [ Options, Events ],
    initialize: function(wrapper, options) {
        this.wrapper = wrapper;
        this.setOptions(options);
        this.element = new Element("div",   { 'class': 'token' });
        this.input   = new Element("input", { 'class': 'token', 'autocomplete': 'off' });

        this.element.grab(this.input);
        // Trigger the data collection callback.

        this.setupInputEvents();
        this.setupFinalizedEvents();
    },
    value: function() {
        return this.element.get('text')
    },
    setupFinalizedEvents: function() {
        this.element.addEvent('click', function(e) {
            e.stop();

            this.wrapper.tokens.each(function(token) {
                $(token).removeClass('selected');
            });
            var token = e.target;
            if (token.hasClass('finalized')) {
                token.addClass('selected');
                var input = token.getElement('input.delete');
                if (!input) {
                    var input = new Element('input', {
                        'class': 'delete',
                        'styles': {
                            'width':   '0px',
                            'height':  '0px',
                            'padding': '0px',
                            'margin':  '0px',
                            'z-index': '-1',
                            'position': 'absolute',
                            'left':     '-100px'
                        },
                        'events': {
                            'keyup': function(e) {
                                e.stop();
                                if (["backspace", "delete"].contains(e.key)) {
                                    this.destroy();
                                    this.wrapper.tokens[this.wrapper.tokens.length - 1].takeFocus();
                                }
                            }.bind(this)
                        }
                    })
                    token.grab(input);
                }
                input.focus()
            }
        }.bind(this));
    },
    setupInputEvents: function() {
        this.input.addEvent('focus', function(e) {
            this.options.data.pass(null,this)();
        }.bind(this));

        /* Autocomplete menu */
        this.input.addEvent('keyup', function(e) {
            /* These keys are trigger actions on the autocomplete menu. */
            var reservedKeys = [ "down", "up",
                                 "enter",
                                 "pageup", "pagedown",
                                 "esc" ];
            if (reservedKeys.contains(e.key)) { return };

            /* signal to destroyPreviousToken() if this input has been edited */
            if (e.target.get('value').length > 0) {
                e.target.addClass('edited')
            }

            var query = e.target.get('value');
            this.showResults(query);

        }.bind(this));

        /* Stop webkit from paging up/down */
        this.input.addEvent('keydown', function(e) {
            var reservedKeys = [ "pageup", "pagedown" ];
            if (reservedKeys.contains(e.key)) { e.stop() };
        });

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
                    if (this.input.get('value').length != 0) {
                        this.down();
                    } else {
                        if (this.resultSet().getChildren("li").length > 0) {
                            this.down();
                        } else {
                            var query = e.target.get('value');
                            this.showResults(query);
                        }
                    }
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
                    //console.log(e.key);
            }

        }.bind(this));

    },
    showResults: function(query) {
        var resultSet = this.resultSet(),
            data      = this.data,
            existing  = this.wrapper.tokens.map(function(token) { return token.value() }),
            results   = data.filter(function(item) {
                return (item.test(query, 'i') && !existing.contains(item) )
            }).sort();

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
    },
    toElement: function() {
       return this.element;
    },
    setValue: function(value) {
        this.element.set('html', value);
    },
    finalize: function() {
        this.element.addClass('finalized');
        this.rehashURL({add: this.value()})
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
    destroy: function() {
        this.wrapper.tokens.erase(this);
        this.wrapper.destroyToken(this);
        this.wrapper.resize();

        this.rehashURL({remove: this.value()})
    },
    destroyPreviousToken: function() {
        var input = this.input.get('value');

        /* Only delete the previous token if:
         *  - the active TokenInput is empty,
         *  - and was empty on the last keystroke.
         */
        if ((input.length == 0 && this.previousInputLength > 0)
            || input.length > 0
            || this.input.hasClass('edited')
           ) {
            this.previousInputLength = input.length;
            return
        } else {
            var token = this.wrapper.tokens[this.wrapper.tokens.length - 2];
            if (token) {
                token.destroy();
                this.wrapper.destroyToken(token);
                this.wrapper.resize();
                this.hideResults();
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

        if ($chk(selected) && selected.hasClass('all')) {
            var token = this;
            this.wrapper.destroyToken(token);

            /* Create a token for each result. */
            resultSet.getElements('li.result').each(function(result) {
                    if (result.hasClass('all')) { return };

                    var text  = result.get('html');
                    var token = this.wrapper.newToken()
                    token.setValue(text);
                    token.finalize();
            }, this);
        } else {
            var token = this.element,
                input = this.input,
                text  = selected.get('html');

            input.destroy();
            this.setValue(text);
            this.finalize();
        }

        // IDEA: do selected.destroy() to remove just the entry?
        resultSet.empty();

        this.wrapper.newToken();

        this.wrapper.resize();
    },
    rehashURL: function(options) {
        // Setup the URL
        var parameters = window.location.hash.slice(1).split('|');

        var parameters = parameters.map(function(parameter) {

            var parts  = parameter.split('='),
                key    = parts[0],
                values = parts[1].split(','),
                value  = options.add || options.remove;

            if (!$chk(parameter)) { return parameter }
            if (value.contains('/') && key == "hosts")    { return parameter }
            if (!value.contains('/') && key == "metrics") { return parameter }

            if (options.add) {
                values.include(value)
            } else {
                values.erase(value)
            }
            values.erase("")

            var string = key + '=' + values.join(',');
            return string
        }.bind(this));

        var hash = parameters.join('|');
        window.location.hash = hash;
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
    options: {
        focus: true
    },
    initialize: function(parent, options) {
        this.setOptions(options);
        this.parent  = $(parent);

        this.element = new Element('div', {'class': 'tokenWrapper'});
        this.results = new Element('ul',  {'class': 'results'});
        this.parent.grab(this.element);
        this.parent.grab(this.results);
        this.tokens  = [];

        if (this.options.tokens) {
            this.options.tokens.each(function(text) {
                var token = this.newToken()
                token.setValue(text);
                token.finalize();
            }.bind(this));
        }
        this.newToken(this.options.focus);

        /* Clicks within the contain focus input on the editable token. */
        this.element.addEvent('click', function() {
            this.tokens.getLast().takeFocus();
        }.bind(this));
    },
    toElement: function() {
        return this.element;
    },
    newToken: function(focus) {
        var token = new SearchToken(this, { 'data': this.options.data });

        this.tokens.include(token);
        this.element.grab(token);

        if (focus != false) {
            token.takeFocus();
        }

        this.resize();

        return token;
    },
    destroyToken: function(token) {
        this.tokens.erase(token);
        $(token).destroy()
    },
    tokenValues: function() {
        return this.tokens.map(function(t) {
            return t.value()
        }).slice(0,-1);
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
    initialize: function(element, options) {
        this.setOptions(options);
        this.builder   = $(element);

        var parameters = window.location.hash.slice(1).split('|');

        parameters.each(function(parameter) {
            if (!$chk(parameter)) { return }

            var parts  = parameter.split('='),
                key    = parts[0],
                values = parts[1].split(',');

            values.erase("")
            this.options[key] = values;
        }.bind(this));

        this.searchers = new Object;
        this.setupHostSearch();
        this.setupMetricSearch();
        this.setupShow();

        /* Display graphs if hosts + metrics have been selected */
        if (this.options.hosts && this.options.metrics) {
            this.showGraphs();
        }
    },
    setupHostSearch: function() {
        var container = this.builder.getElement("div#hosts div.search"),
            searcher  = new TokenSearch(container, {
                'tokens':   this.options.hosts,
                'data':     this.getHosts
            });
        this.searchers.host = searcher;
    },
    setupMetricSearch: function() {
        var container = this.builder.getElement("div#metrics div.search"),
            searcher  = new TokenSearch(container, {
                'tokens':   this.options.metrics,
                'data':     this.getMetrics,
                'focus':    false
            });
        this.searchers.metric = searcher;
    },
    setupSave: function() {
        if (!this.save) {
            var profile_name = this.profile_name = new Element('input', {
                'id':    'profile_name',
                'type':  'text',
                'class': 'text',
                'value': $('name') ? $('name').get('text') : ''
            });

            var show = this.builder.getElement('input#show');
            var save = this.save = new Element('input', {
                'id':    'save',
                'type':  'button',
                'class': 'button',
                'value': 'Save profile',
                'events': {
                    'click': function() {
                        var hosts   = this.searchers.host.tokenValues(),
                            metrics = this.searchers.metric.tokenValues();

                        var jsonRequest = new Request.JSON({
                            method:    'post',
                            url:       '/builder',
                            onSuccess: function(response) {
                                new Message({
                                    title:    'Profile saved',
                                    message:  '"' + profile_name.get('value') + '"',
                                    top:      true,
                                    iconPath: '/images/',
                                    icon:     'ok.png',
                                }).say();
                            },
                        }).send({'data': {
                            'hosts':        hosts,
                            'metrics':      metrics,
                            'profile_name': profile_name.get('value')
                        }});

                    }.bind(this)
                }
            });

            save.fade('hide')
            show.grab(save, 'after');

            profile_name.fade('hide')
            save.grab(profile_name, 'after');
        }
    },
    setupShow: function() {
        var show = this.builder.getElement('input#show');

        /* Button to save profile */
        show.addEvent('click', function(e) {
            this.setupSave();
        }.bind(this));

        /* Display the graphs */
        show.addEvent('click', function(e) {
            e.stop();

            this.showGraphs();

            // Fade the save button once graphs have been rendered.
            save.fade.delay(1500, save, 'in')
            profile_name.fade.delay(1500, profile_name, 'in')
        }.bind(this));

    },
    showGraphs: function() {
        window.Graphs = [];

        var hosts   = $(this.searchers.host).getElements("div.token.finalized"),
            metrics = $(this.searchers.metric).getElements("div.token.finalized");

        var hosts   = hosts.map(function(el) { return el.get('text') }),
            metrics = metrics.map(function(el) { return el.get('text') }),
            graphs  = $('graphs'),
            save    = this.save;
            profile_name = this.profile_name;

        graphs.empty();
        hosts.each(function(host) {
            /* Separate each plugin onto its own graph */
            var plugins = {};
            metrics.each(function(m) {
                var parts  = m.split('/'),
                    plugin = parts[0],
                    metric = parts[1];

                if (! plugins[plugin]) {
                    plugins[plugin] = []
                }

                plugins[plugin].push(metric)
            });

            /* Create the graphs */
            $each(plugins, function(metrics, plugin) {
                var element = new Element('div', {'class': 'graph'});
                graphs.grab(element);

                var graph = new VisageGraph(element, host, plugin, {
                    pluginInstance: metrics.join(',')
                });

                window.Graphs.include(graph);
            });
        }.bind(this));
    },
    getHosts: function() {
        var request = new Request.JSONP({
            url:    "/data",
            method: "get",
            onRequest:  function(json) {
                this.data = [];
            },
            onComplete: function(json) {
                this.data = json.hosts;
            }.bind(this)
        }).send();

        return request;
    },
    getMetrics: function(hosts) {
        var builder = $(this.wrapper).getParent('div#chart-builder'),
            tokens  = builder.getElement("div#hosts div.tokenWrapper"),
            hosts   = tokens.getElements("div.token.finalized").map(function(token) {
                return token.get('text');
            });

        var url     = "/data/" + hosts.join(',');
        var request = new Request.JSONP({
            url:    url,
            method: "get",
            onComplete: function(json) {
                this.data = json.metrics;
            }.bind(this)
        }).send();

        return request;
    }
});
