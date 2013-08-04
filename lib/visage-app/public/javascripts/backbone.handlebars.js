// backbone.handlebars v0.2.0
//
// Copyright (c) 2013 Loïc Frering <loic.frering@gmail.com>
// Distributed under the MIT license

(function() {

var originalNameLookup = Handlebars.JavaScriptCompiler.prototype.nameLookup;

Handlebars.JavaScriptCompiler.prototype.nameLookup = function(parent, name, type) {
  statement =  '(function() {'
  statement += 'if (typeof ' + parent + '.' + name + ' === "function") { return ' + parent + '.' + name + '() } '
  statement += 'else if (' + parent + '.get) { return ' + parent + '.get("' + name + '") } '
  statement += 'else { return ' + originalNameLookup.apply(this, arguments) + '}})()'
  return statement

  //return parent + ".get ? " + parent + ".get('" + name + "') : " + originalNameLookup.apply(this, arguments);
};

var HandlebarsView = Backbone.View.extend({
  render: function() {
    var context = this.context();

    if (_.isString(this.template)) {
      this.template = Handlebars.compile(this.template, {knownHelpersOnly: true});
    }

    if (_.isFunction(this.template)) {
      var html = this.template(context, {data: {view: this}});
      this.$el.html(html);
    }
    this.renderNestedViews();
    return this;
  },

  renderNestedViews: function() {
    _.each(this.nestedViews, function(nestedView, id) {
      this.resolveViewClass(nestedView.name, _.bind(function(viewClass) {
        this.renderNestedView(id, viewClass, nestedView.options);
      }, this));
    }, this);
  },

  renderNestedView: function(id, viewClass, options) {
    var $el = this.$('#' + id);
    if ($el.size() === 1) {
      var view = new viewClass(options);
      $el.replaceWith(view.$el);
      view.render();
    }
  },

  resolveViewClass: function(name, callback) {
    if (_.isFunction(name)) {
      return callback(name);
    } else if (_.isString(name)) {
      var parts, i, len, obj;
      parts = name.split(".");
      for (i = 0, len = parts.length, obj = window; i < len; ++i) {
          obj = obj[parts[i]];
      }
      if (obj) {
        return callback(obj);
      } else if (typeof require !== 'undefined') {
        return require([name], callback);
      }
    }
    throw new Error('Cannot resolve view "' + name + '"');
  },

  context: function() {
    return this.model || this.collection || {};
  }
});

Handlebars.registerHelper('each', function(context, options) {
  var fn = options.fn, inverse = options.inverse;
  var i = 0, ret = "", data;
  var current;

  if (options.data) {
    data = Handlebars.createFrame(options.data);
  }

  if (context && typeof context === 'object') {
    if (context instanceof Array || context instanceof Backbone.Collection) {
      for (var j = context.length; i<j; i++) {
        if (data) { data.index = i; }
        current = context.at ? context.at(i) : context[i];
        ret = ret + fn(current, { data: data });
      }
    } else {
      for (var key in context) {
        if (context.hasOwnProperty(key)) {
          if (data) { data.key = key; }
          ret = ret + fn(context[key], {data: data});
          i++;
        }
      }
    }
  }

  if (i === 0) {
    ret = inverse(this);
  }

  return ret;
});

uid = 1;

Handlebars.registerHelper('view', function(name, options) {
  var id = 'bbhbs-' + uid++;

  if (!options.data || !options.data.view) {
    throw new Error('A nested view must be defined in a HandlebarsView.');
  }
  var parentView = options.data.view;
  parentView.nestedViews = parentView.nestedViews || {};
  parentView.nestedViews[id] = {
    name: name,
    options: options.hash
  };

  return new Handlebars.SafeString('<div id="' + id + '"></div>');
});

  Backbone.HandlebarsView = HandlebarsView;
})();
