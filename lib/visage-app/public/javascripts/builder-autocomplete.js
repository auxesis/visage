var HostAutocomplete = new Class({
    Implements: [ Options, Events ],
    initialize: function(element) {
        this.element = $(element);
        this.cacheData();

        this.element.addEvent('keyup', function(e) {
            var input    = e.target,
                hosts    = this.hosts.hosts,
                query    = input.get('value'),
                results  = hosts.filter(function(host) { return host.test(query, 'i') });
                selected = $$('div#hosts ul.selected')[0]

            selected.empty();
            results.each(function(host) {
                var result = new Element('li', { 'html': host });
                selected.grab(result);
            });

        }.bind(this));
    },
    cacheData: function() {
        var request = new Request.JSONP({
            url:    "/data",
            method: "get",
            onComplete: function(json) {
                this.hosts = json;
            }.bind(this)
        }).send();

        return
    }
});

window.addEvent('domready', function() {

    new HostAutocomplete('hosts-search');

});
