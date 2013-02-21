/*
---
description:     LightFace.IFrame

authors:
  - David Walsh (http://davidwalsh.name)

license:
  - MIT-style license

requires:
  core/1.2.1:   "*"

provides:
  - LightFace.IFrame
...
*/
LightFace.IFrame = new Class({
	Extends: LightFace,
	options: {
		url: ""
	},
	initialize: function(options) {
		this.parent(options);
		if(this.options.url) this.load();
	},
	load: function(url, title) {
		this.fade();
		if(!this.iframe) {
			this.messageBox.set("html", "");
			this.iframe = new IFrame({
				styles: {
					width: "100%",
					height: "100%"
				},
				events: {
					load: function() {
						this.unfade();
						this.fireEvent("complete");
					}.bind(this)
				},
				border: 0
			}).inject(this.messageBox);
			this.messageBox.setStyles({ padding: 0, overflow: "hidden" });
		}
		if(title) this.title.set("html", title);
		this.iframe.src = url || this.options.url;
		this.fireEvent("request");
		return this;
	}
});