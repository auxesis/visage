/**
 * MooToolsAdapter 0.1
 * For all details and documentation:
 * http://github.com/inkling/backbone-mootools
 *
 * Copyright 2011 Inkling Systems, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This file provides a basic jQuery to MooTools Adapter. It allows us to run Backbone.js
 * with minimal modifications.
 */
(function(window){
    var MooToolsAdapter = new Class({
        initialize: function(elements){
            for (var i = 0; i < elements.length; i++){
                this[i] = elements[i];
            }
            this.length = elements.length;
        },

        /**
         * Hide the elements defined by the MooToolsAdapter from the screen.
         */
        hide: function(){
            for (var i = 0; i < this.length; i++){
                this[i].setStyle('display', 'none');
            }
            return this;
        },

        /**
         * Append the frst element in the MooToolsAdapter to the elements found by the passed in
         * selector. If the selector selects more than one element, a clone of the first element is
         * put into every selected element except the first. The first selected element always
         * adopts the real element.
         *
         * @param selector A CSS3 selector.
         */
        appendTo: function(selector){
            var elements = window.getElements(selector);

            for (var i = 0; i < elements.length; i++){
                if (i > 0){
                    elements[i].adopt(Object.clone(this[0]));
                } else {
                    elements[i].adopt(this[0]);
                }
            }

            return this;
        },

        /**
         * Set the attributes of the element defined by the MooToolsAdapter.
         *
         * @param map:Object literal map definining the attributes and the values to which
         *     they should be set.
         *
         * @return MooToolsAdapter The object on which this method was called.
         */
        attr: function(map){
            for (var i = 0; i < this.length; i++){
                this[i].set(map);
            }
            return this;
        },

        /**
         * Set the HTML contents of the elements contained by the MooToolsAdapter.
         *
         * @param htmlString:String A string of HTML text.
         *
         * @return MooToolsAdapter The object the method was called on.
         */
        html: function(htmlString){
            if (typeof htmlString === 'undefined') {
                return this[0].get('html');
            } else {
                for (var i = 0; i < this.length; i++){
                    this[i].set('html', htmlString);
                }
            }
            return this;
        },

        /**
         * Remove an event namespace from an eventName.
         * For Example: Transform click.mootools -> click
         *
         * @param eventName:String A string representing an event name.
         *
         * @return String A string representing the event name passed without any namespacing.
         */
        removeNamespace_: function(eventName){
            var dotIndex = eventName.indexOf('.');

            if (dotIndex != '-1'){
                eventName = eventName.substr(0, dotIndex);
            }

            return eventName;
        },

        /**
         * Delegate an event that is fired on the elements defined by the selector to trigger the
         * passed in callback.
         *
         * @param selector:String A CSS3 selector defining which elements should be listenining to
         *     the event.
         * @param eventName:String The name of the event.
         * @param method:Function The callback to call when the event is fired on the proper
         *     element.
         *
         * @return MooToolsAdapter The object the method was called on.
         */
        delegate: function(selector, eventName, method){
            // Remove namespacing because it's not supported in MooTools.
            eventName = this.removeNamespace_(eventName);

            // Note: MooTools Delegation does not support delegating on blur and focus yet.
            for (var i = 0; i < this.length; i++){
                this[i].addEvent(eventName + ':relay(' + selector + ')', method);
            }
            return this;
        },

        /**
         * Bind the elements on the MooToolsAdapter to call the specific method for the specific
         * event.
         *
         * @param eventName:String The name of the event.
         * @param method:Function The callback to apply when the event is fired.
         *
         * @return MooToolsAdapter The object the method was called on.
         */
        bind: function(eventName, method){
            // Remove namespacing because it's not supported in MooTools.
            eventName = this.removeNamespace_(eventName);

            // Bind the events.
            for (var i = 0; i < this.length; i++){
                if (eventName == 'popstate' || eventName == 'hashchange'){
                    this[i].addEventListener(eventName, method);
                } else {
                    this[i].addEvent(eventName, method);
                }
            }
            return this;
        },

        /**
         * Unbind the bound events for the element.
         */
        unbind: function(eventName){
            // Remove namespacing because it's not supported in MooTools.
            eventName = this.removeNamespace_(eventName);

            for (var i = 0; i < this.length; i++){
                if (eventName !== ""){
                    this[i].removeEvent(eventName);
                } else {
                    this[i].removeEvents();
                }
            }
            return this;
        },

        /**
         * Return the element at the specified index on the MooToolsAdapter.
         * Equivalent to MooToolsAdapter[index].
         *
         * @param index:Number a numerical index.
         *
         * @return HTMLElement An HTML element from the MooToolsAdapter. Returns undefined
         *     if an element at that index does not exist.
         */
        get: function(index){
            return this[index];
        },

         /**
          * Removes from the DOM all the elements selected by the MooToolsAdapter.
          */
        remove: function(){
            for (var i = 0; i < this.length; i++){
                this[i].dispose();
            }
            return this;
        },

        /**
         * Add a callback for when the document is ready.
         */
        ready: function(callback){
            for (var i = 0; i < this.length; i++){
                window.addEvent('domready', callback);
            }
        },

        /**
         * Return the text content of all the elements selected by the MooToolsAdapter.
         * The text of the different elements is seperated by a space.
         *
         * @return String The text contents of all the elements selected by the MooToolsAdapter.
         */
        text: function(){
            var text = [];
            for (var i = 0; i < this.length; i++){
                text.push(this[i].get('text'));
            }
            return text.join(' ');
        },

        /**
         * Fire a specific event on the elements selected by the MooToolsAdapter.
         *
         * @param trigger:
         */
        trigger: function(eventName){
            for (var i = 0; i < this.length; i++){
                this[i].fireEvent(eventName);
            }
            return this;
        },

        /**
         * Find all elements that match a given selector which are descendants of the
         * elements selected the MooToolsAdapter.
         *
         * @param selector:String - A css3 selector;
         *
         * @return MooToolsAdapter A MooToolsAdapter containing the selected
         *     elements.
         */
        find: function(selector){
            var elements = new Elements();
            for (var i = 0; i < this.length; i++){
                var result = this[i].getElements(selector);
                elements = elements.concat(result);
            }
            return new MooToolsAdapter(elements);
        }
    });

    /**
     * JQuery Selector Methods
     *
     * jQuery(html) - Returns an HTML element wrapped in a MooToolsAdapter.
     * jQuery(expression) - Returns a MooToolsAdapter containing an element set corresponding the
     *     elements selected by the expression.
     * jQuery(expression, context) - Returns a MooToolsAdapter containing an element set corresponding
     *     to applying the expression in the specified context.
     * jQuery(element) - Wraps the provided element in a MooToolsAdapter and returns it.
     *
     * @return MooToolsAdapter an adapter element containing the selected/constructed
     *     elements.
     */
    window.jQuery = function(expression, context){
        var elements;

        // Handle jQuery(html).
        if (typeof expression === 'string' && !context){
            if (expression.charAt(0) === '<' && expression.charAt(expression.length - 1) === '>'){
                elements = [new Element('div', {
                    html: expression
                }).getFirst()];
                return new MooToolsAdapter(elements);
            }
        } else if (typeof expression == 'object'){
            if (instanceOf(expression, MooToolsAdapter)){
                // Handle jQuery(MooToolsAdapter)
                return expression;
            } else {
                // Handle jQuery(element).
                return new MooToolsAdapter([expression]);
            }
        }

        // Handle jQuery(expression) and jQuery(expression, context).
        context = context || document;
        elements = context.getElements(expression);
        return new MooToolsAdapter(elements);
    };

    /*
     * jQuery.ajax
     *
     * Maps a jQuery ajax request to a MooTools Request and sends it.
     */
    window.jQuery.ajax = function(params){
        var emulation = false;
        var data = params.data;
        if (Backbone.emulateJSON){
            emulation = true;
            data = data ? { model: data } : {};
        }

        var parameters = {
            url: params.url,
            method: params.type,
            data: data,
            emulation: emulation,
            onSuccess: function(responseText){
                params.success(JSON.parse(responseText));
            },
            onFailure: params.error,
            headers: { 'Content-Type': params.contentType }
        };

        new Request(parameters).send();
    };

})(window);
