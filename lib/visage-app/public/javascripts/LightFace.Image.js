/*
---
description:     LightFace.Image

authors:
  - David Walsh (http://davidwalsh.name)

license:
  - MIT-style license	

requires:
  core/1.2.1:   "*"

provides:
  - LightFace.Image
...
*/
LightFace.Image = new Class({
	Extends: LightFace,
	options: {
		constrain: true,
		url: ""
	},
	initialize: function(options) {
		this.parent(options);
		this.url = "";
		this.resizeOnOpen = false;
		if(this.options.url) this.load();
	},
	_resize: function() {
		//get the largest possible height
		var maxHeight = window.getSize().y - this.options.pad;
		
		//get the image size
		var imageDimensions = document.id(this.image).retrieve("dimensions");
		
		//if image is taller than window...
		if(imageDimensions.y > maxHeight) {
			this.image.height = maxHeight;
			this.image.width = (imageDimensions.x * (maxHeight / imageDimensions.y));
			this.image.setStyles({
				height: maxHeight,
				width: (imageDimensions.x * (maxHeight / imageDimensions.y)).toInt()
			});
		}
		
		//get rid of styles
		this.messageBox.setStyles({ height: "", width: "" });
		
		//position the box
		this._position();
	},
	load: function(url, title) {
		//keep current height/width
		var currentDimensions = { x: "", y: "" };
		if(this.image) currentDimensions = this.image.getSize();
		///empty the content, show the indicator
		this.messageBox.set("html", "").addClass("lightFaceMessageBoxImage").setStyles({
			width: currentDimensions.x,
			height: currentDimensions.y
		});
		this._position();
		this.fade();
		this.image = new Element("img", {
			events: {
				load: function() {
					(function() {
						var setSize = function() { 
							this.image.inject(this.messageBox).store("dimensions", this.image.getSize()); 
						}.bind(this);
						setSize();
						this._resize();
						setSize(); //stupid ie
						this.unfade();
						this.fireEvent("complete");
					}).bind(this).delay(10);
				}.bind(this),
				error: function() {
					this.fireEvent("error");
					this.image.destroy();
					delete this.image;
					this.messageBox.set("html", this.options.errorMessage).removeClass("lightFaceMessageBoxImage");
				}.bind(this),
				click: function() {
					this.close();
				}.bind(this)
			},
			styles: {
				width: "auto",
				height: "auto"
			}
		});
		this.image.src = url || this.options.url;
		if(title && this.title) this.title.set("html", title);	
		return this;
	}
});