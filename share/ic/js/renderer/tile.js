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
    "ic-renderer-tile",
    function(Y) {
        var BUTTON_POLLING_IS_ACTIVE_TOGGLE_ON  = 'Auto Update: On';
        var BUTTON_POLLING_IS_ACTIVE_TOGGLE_OFF = 'Auto Update: Off';

        var Clazz = Y.namespace("IC").RendererTile = Y.Base.create(
            "ic_renderer_tile",
            Y.IC.RendererBase,
            [ Y.WidgetParent, Y.WidgetStdMod ],
            {
                _header_node:    null,
                _title_node:     null,
                _mesg_node:      null,
                _button_node:    null,

                _refresh_button: null,
                _polling_button: null,

                _initial_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._initial_action = config.initial_action;

                    this.set("width", this.get("advisory_width"));
                    this.set("height", this.get("advisory_height"));

                    this.plug(
                        Y.Plugin.Cache,
                        {
                            uniqueKeys: true,
                            max:        100
                        }
                    );
                    Y.log(Clazz.NAME + "::initializer - cache: " + this.cache);
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._header_node    = null;
                    this._title_node     = null;
                    this._mesg_node      = null;
                    this._button_node    = null;
                    this._refresh_button = null;
                    this._polling_button = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    // TODO: use class manager

                    this._action_buttons_node = Y.Node.create('<span class="ic_renderer_tile_header_buttons_actions"></span>');

                    this._title_node  = Y.Node.create('<div class="ic_renderer_tile_header_title yui3-u-1-3">Tile Title</div>');
                    this._button_node = Y.Node.create('<div class="ic_renderer_tile_header_buttons yui3-u-2-3"></div>');
                    this._button_node.append(this._action_buttons_node);

                    this._mesg_node   = Y.Node.create('<div class="ic_renderer_tile_header_mesg yui3-u-1"></div>');
                    this._header_node = Y.Node.create('<div class="ic_renderer_tile_header yui3-g"></div>');

                    this._header_node.append( this._title_node );
                    this._header_node.append( this._button_node );
                    this._header_node.append( this._mesg_node );

                    if (Y.Lang.isValue(this.get("url"))) {
                        if (this.get("polling_interval") > 0) {
                            this._polling_button = new Y.Button (
                                {
                                    render:   this._button_node,
                                    label:    (this.get("polling_is_active") ? BUTTON_POLLING_IS_ACTIVE_TOGGLE_ON : BUTTON_POLLING_IS_ACTIVE_TOGGLE_OFF),
                                    callback: Y.bind(
                                        function () {
                                            Y.log(Clazz.NAME + "::renderUI - polling button callback");

                                            Y.log(Clazz.NAME + "::renderUI - polling_is_active: " + this.get("polling_is_active"));
                                            if (this.get("polling_is_active")) {
                                                this.set("polling_is_active", false);
                                            }
                                            else {
                                                this.set("polling_is_active", true);
                                            }
                                        },
                                        this
                                    )
                                }
                            );
                        }
                        this._refresh_button = new Y.Button (
                            {
                                render:   this._button_node,
                                label:    "Refresh",
                                callback: Y.bind(
                                    function () {
                                        Y.log(Clazz.NAME + "::renderUI - refresh button callback");
                                        this._refreshData();
                                    },
                                    this
                                )
                            }
                        );
                    }

                    this.set("headerContent", this._header_node );
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");
                    this.after(
                        "titleChange",
                        function (e) {
                            this._title_node.setContent( this.get("title") );
                        },
                        this
                    );
                    this.after(
                        "selectionChange",
                        Y.bind( this._afterMySelectionChange, this )
                    );
                    this.after(
                        "actionChange",
                        Y.bind( this._afterActionChange, this )
                    );

                    if (Y.Lang.isValue(this.get("url"))) {
                        // TODO: need to wire in change for polling interval,
                        //       and/or detach/attach of other handler(s)
                        if (this.get("polling_interval") > 0) {
                            this.after(
                                "polling_is_activeChange",
                                function (e) {
                                    Y.log(Clazz.NAME + "::renderUI - polling_is_active change: " + e.newVal);
                                    if (e.newVal) {
                                        this._polling_button.set("label", BUTTON_POLLING_IS_ACTIVE_TOGGLE_ON);

                                        this._initTimer();
                                    }
                                    else {
                                        this._polling_button.set("label", BUTTON_POLLING_IS_ACTIVE_TOGGLE_OFF);

                                        if (this._timer) {
                                            this._timer.cancel();
                                        }
                                    }
                                },
                                this
                            );
                        }
                    }
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    this._title_node.setContent( this.get("title") );
                    this._mesg_node.setContent("Initially loaded: " + new Date ());

                    // needed this to make sure the body node exists
                    this.set("bodyContent", "");

                    Y.log("actions: " + Y.Object.keys(this.get("actions")));
                    if (Y.Object.keys(this.get("actions")).length > 1) {
                        Y.each(
                            this.get("actions"),
                            function (v, k, obj) {
                                Y.log(Clazz.NAME + "::renderUI - adding action button: " + v.label);
                                var button = new Y.Button (
                                    {
                                        render:   this._action_buttons_node,
                                        label:    v.label,
                                        callback: Y.bind(
                                            function () {
                                                Y.log(Clazz.NAME + "::renderUI - button callback: " + k);
    
                                                this.set("action", k);
                                            },
                                            this
                                        )
                                    }
                                );
                            },
                            this
                        );
                    }

                    // TODO: the following code has an issue such that the existing displayed
                    //       record is not hidden correctly, fix it
                    var initial_action = this.get("action");
                    //Y.log(Clazz.NAME + "::syncUI - actions: " + Y.dump(this.get("actions")));
                    //if (! Y.Lang.isValue( initial_action ) && Y.Lang.isValue( this.get("actions") )) {
                        //var found = Y.some(
                            //this.get("actions"),
                            //function (v, k, o) {
                                //if (Y.Lang.isValue(v.is_default) && v.is_default) {
                                    //initial_action = k
                                    //return true;
                                //}
                            //}
                        //);
                        //if (! found) {
                            //if (Y.Lang.isValue(this.get("actions").DetailView)) {
                                //initial_action = "DetailView";
                            //}
                            //else {
                                //initial_action = Y.Object.keys(this.get("actions"))[0];
                            //}
                        //}
                    //}
                    //else {
                        //// TODO: need to do this only if there is default content
                        ////       and then handle clearing it on first display
                        ////this.set("bodyContent", "Select an action to load content.");
                    //}

                    Y.log(Clazz.NAME + "::syncUI - initial_action: " + Y.dump(initial_action));
                    if (Y.Lang.isValue( initial_action ) && Y.Lang.isValue(this.get("actions")[initial_action])) {
                        // TODO: is there a more proper YUI way to do this?
                        // get the side effect of setting action
                        this._afterActionChange(
                            {
                                newVal: initial_action
                            }
                        );
                    }

                    if (Y.Lang.isValue(this.get("url"))) {
                        // TODO: need to wire in change for polling interval,
                        //       and/or detach/attach of other handler(s)
                        if (this.get("polling_is_active") && this.get("polling_interval") > 0) {
                            Y.log(Clazz.NAME + "::syncUI - starting polling");
                            this._initTimer();
                        }
                    }
                },

                _initTimer: function () {
                    Y.log(Clazz.NAME + "::_initTimer: " + this.get("polling_interval"));
                    this._timer = Y.later(
                        (this.get("polling_interval") * 1000),
                        this,
                        function () {
                            this._refreshData();
                        },
                        null,
                        true        // make periodic (continuous)
                    );
                },

                _afterMySelectionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterMySelectionChange");
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterMySelectionChange - e.newVal: " + e.newVal);
                    if (Y.Lang.isValue(e.prevVal)) {
                        e.prevVal.hide();
                    }
                    if (Y.Lang.isValue(e.newVal)) {
                        e.newVal.show();
                    }
                },

                _afterActionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterActionChange");
                    Y.log(Clazz.NAME + "::_afterActionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterActionChange - e.newVal: " + e.newVal);
                    var action_key = e.newVal;

                    var cache_entry = this.cache.retrieve(action_key);;
                    Y.log(Clazz.NAME + "::_afterActionChange - cache_entry: " + Y.dump(cache_entry));

                    var child;

                    if (! Y.Lang.isValue(cache_entry)) {
                        this._uiSetFillHeight( Y.WidgetStdMod.BODY );

                        var action_data = this.get("actions")[action_key];
                        Y.log(Clazz.NAME + "::_buildActionContent - action_data: " + Y.dump(action_data));

                        var body_node = this.getStdModNode( Y.WidgetStdMod.BODY );

                        var region    = body_node.get("region");
                        Y.log(Clazz.NAME + "::_buildActionContent - body region: " + Y.dump(region));

                        action_data.renderer.config.render          = body_node;
                        action_data.renderer.config.advisory_width  = region.width;
                        action_data.renderer.config.advisory_height = region.height;

                        child = Y.IC.Renderer.buildContent( action_data.renderer );
                        Y.log(Clazz.NAME + "::_buildActionContent - child from new: " + child);

                        this.add(child);

                        this.cache.add(action_key, child);
                    }
                    else {
                        child = cache_entry.response;
                        Y.log(Clazz.NAME + "::_afterActionChange - child from cache: " + child);
                    }

                    //
                    // see comments in panel.js as to why this breaks when nested directly
                    // inside of a renderer that is widget parent/child
                    //
                    //this.selectChild( child.get("index") );
                    child.set("selected", 2);
                },

                //
                // this is overriding the base provided method so that the tile's children
                // (the actions) don't get de-selected when the parent itself is deselected
                // as is the case when a tile is a child of a panel/grid, etc.
                //
                _afterParentSelectedChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterParentSelectedChange");
                },

                _refreshData: function () {
                    Y.log(Clazz.NAME + "::_refreshData");

                    this._mesg_node.setContent("Reloading...");

                    Y.log(Clazz.NAME + "::_refreshData - url: " + this.get("url"));
                    Y.io(
                        this.get("url"),
                        {
                            on: {
                                success: Y.bind(this._onRequestSuccess, this),
                                failure: Y.bind(this._onRequestFailure, this)
                            }
                        }
                    );
                },

                _onRequestSuccess: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestSuccess");

                    // TODO: this could be attached to a handler on "actions"
                    this._action_buttons_node.setContent("");

                    //this.set("action", null);

                    this.removeAll();

                    // TODO: this should be handled by a removeChild handler that clears the cached record
                    this.cache.flush();

                    this._mesg_node.setContent("Parsing...");

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        this._mesg_node.setContent("Last Tried: " + new Date () + " (Can't parse JSON response: " + e + ")");

                        return;
                    }
                    if (new_data) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - new_data: " + Y.dump(new_data));

                        if (this._timer) {
                            this._timer.cancel();
                        }

                        this.set("actions", new_data.actions);
                        this.set("title", new_data.title);
                        // TODO: should this get updated?
                        //this.set("url", new_data.url);

                        this.syncUI();

                        this._mesg_node.setContent("Last Updated: " + new Date ());
                    }
                    else {
                        this._mesg_node.setContent("Last Tried: " + new Date () + " (No data in response)");
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");

                    this._mesg_node.setContent("Last Tried: " + new Date () + " (Request failed: "  + response.status + " - " + response.statusText + ")");
                }
            },
            {
                ATTRS: {
                    //
                    // if a URL has been specified this tile can reload its configuration data
                    // from the specified URL and hence automagically provides a refresh button 
                    // to allow the user to do so
                    //
                    url: {
                        value: null
                    },
                    title: {
                        value: ""
                    },
                    polling_is_active: {
                        value:     false,
                        validator: Y.Lang.isBoolean
                    },
                    polling_interval: {
                        // in number of seconds
                        value:     0,
                        validator: Y.Lang.isNumber
                    },
                    actions: {
                        value: {}
                    },
                    action: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-tile-css",
            "ic-renderer-base",
            "widget-std-mod",
            "gallery-button",
            "cache"
        ]
    }
);
