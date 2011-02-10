/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-renderer-panel",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererPanel = Y.Base.create(
            "ic_renderer_panel",
            Y.IC.RendererBase,
            //
            // implementing the panel as a parent means that the data
            // objects that are its children must have Y.WidgetChild
            // in their definition
            //
            [ Y.WidgetParent ],
            {
                // data store keyed on a unique key that will be used when
                // needing to build the data, stores configuration information
                // needed to build the display of the specific data item
                _data: null,

                // if we are constructed with an action have it passed through
                // to the renderer that is used for the default record
                _default_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._data = config.data;

                    if (Y.Lang.isValue( config.action )) {
                        this._default_action = config.action;
                        Y.log(Clazz.NAME + "::initializer - _default_action: " + this._default_action);
                    }

                    this.plug(
                        Y.Plugin.Cache,
                        {
                            uniqueKeys: true,
                            max:        100
                        }
                    );
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._data = null;
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    this.after(
                        "currentChange",
                        Y.bind( this._afterCurrentChange, this )
                    );
                    this.after(
                        "selectionChange",
                        Y.bind( this._afterMySelectionChange, this )
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    this.set("headerContent", "header");

                    // TODO: only set default when no current already selected
                    var default_key;

                    var default_found = Y.some(
                        this._data,
                        function (v, k, obj) {
                            if (Y.Lang.isValue(v.is_default) && v.is_default) {
                                default_key = k;
                                return true;
                            }
                        }
                    );
                    if (default_found) {
                        Y.log(Clazz.NAME + "::syncUI - default_key: " + default_key);
                        this.set("current", default_key);
                    }
                    else {
                        this.set("bodyContent", "No default data to load.");
                    }
                },

                _afterMySelectionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterMySelectionChange");
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.newVal:"  + e.newVal);
                    if (Y.Lang.isValue(e.prevVal)) {
                        e.prevVal.hide();
                    }
                    if (Y.Lang.isValue(e.newVal)) {
                        e.newVal.show();
                    }
                },

                _afterCurrentChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterCurrentChange");
                    Y.log(Clazz.NAME + "::_afterCurrentChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterCurrentChange - e.newVal: " + e.newVal);
                    var cache_key = e.newVal;

                    var cache_entry = this.cache.retrieve(cache_key);
                    //Y.log(Clazz.NAME + "::_afterCurrentChange - cache_entry: " + Y.dump(cache_entry));

                    var child;

                    if (! Y.Lang.isValue(cache_entry)) {
                        var data = this._data[cache_key];

                        var settings;
                        if (Y.Lang.isValue(data.content)) {
                            settings = data.content;
                        }
                        else if (Y.Lang.isValue(data.renderer)) {
                            settings = data.renderer;
                        }

                        if (Y.Lang.isValue(this._default_action) && ! Y.Lang.isValue(settings.config.action)) {
                            settings.config.action = this._default_action;
                        }

                        settings.config.render          = this.get("contentBox");
                        settings.config.advisory_width  = this.get("width");
                        settings.config.advisory_height = this.get("height");

                        child = Y.IC.Renderer.buildContent(settings);

                        this.add(child);

                        this.cache.add(cache_key, child);
                    }
                    else {
                        child = cache_entry.response;
                        Y.log(Clazz.NAME + "::_afterActionChange - child from cache: " + child);
                    }

                    //
                    // selectChild didn't work here because it sets selected to "1"
                    // but we need it to be "2", I don't fully understand why but it
                    // has to do with how multiple parent+child relationships are
                    // combined
                    //
                    //this.selectChild( this._data_to_index_map[e.newVal] );
                    child.set("selected", 2);
                }
            },
            {
                ATTRS: {
                    current: {
                        value: null
                    }
                }
            }
        );

        Y.IC.Renderer.registerConstructor("Panel", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-panel-css",
            "ic-renderer-base",
            "ic-renderer-tile",
            "cache"
        ]
    }
);
