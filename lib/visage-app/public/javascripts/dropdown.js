//This library: http://dev.clientcide.com/depender/build?download=true&version=MooTools+Bootstrap&require=Bootstrap%2F
//Contents: Bootstrap:Source/UI/Bootstrap.js, Core:Source/Core/Core.js, Core:Source/Types/Array.js, Core:Source/Types/

// Begin: Source/UI/Bootstrap.js
/*
---

name: Bootstrap

description: The BootStrap namespace.

authors: [Aaron Newton]

license: MIT-style license.

provides: [Bootstrap]

...
*/
var Bootstrap = {
    version: 3
};

// Begin: Source/UI/Bootstrap.Dropdown.js
/*
---

name: Bootstrap.Dropdown

description: A simple dropdown menu that works with the Twitter Bootstrap css framework.

license: MIT-style license.

authors: [Aaron Newton]

requires:
 - /Bootstrap
 - Core/Element.Event
 - More/Element.Shortcuts

provides: Bootstrap.Dropdown

...
*/
Bootstrap.Dropdown = new Class({

	Implements: [Options, Events],

	options: {
		/*
			onShow: function(element){},
			onHide: function(elements){},
		*/
		ignore: 'input, select, label'
	},

	initialize: function(container, options){
		this.element = document.id(container);
		this.setOptions(options);
		this.boundHandle = this._handle.bind(this);
		document.id(document.body).addEvent('click', this.boundHandle);
	},

	hideAll: function(){
		var els = this.element.removeClass('open').getElements('.open').removeClass('open');
		this.fireEvent('hide', els);
		return this;
	},

	show: function(subMenu){
		this.hideAll();
		this.fireEvent('show', subMenu);
		subMenu.addClass('open');
		return this;
	},

	destroy: function(){
		this.hideAll();
		document.body.removeEvent('click', this.boundHandle);
		return this;
	},

	// PRIVATE

	_handle: function(e){
		var el = e.target;
		var open = el.getParent('.open');
		if (!el.match(this.options.ignore) || !open) this.hideAll();
		if (this.element.contains(el)) {
			var parent;
			if (el.match('[data-toggle="dropdown"]') || el.getParent('[data-toggle="dropdown"] !')){
				parent = el.getParent('.dropdown, .btn-group');
			}
			// backwards compatibility
			if (!parent) parent = el.match('.dropdown-toggle') ? el.getParent() : el.getParent('.dropdown-toggle !');
			if (parent){
				e.preventDefault();
				if (!open) this.show(parent);
			}
		}
	}
});

