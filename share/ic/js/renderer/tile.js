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

                _pending_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

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

                    this._mesg_node   = Y.Node.create('<div class="ic_renderer_tile_header_mesg yui3-u-1">Initially loaded: ' + new Date () + '</div>');
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

                    //
                    // if there is an action set, indicate that we need
                    // to load it later during syncUI so that it is 
                    // handled appropriately wrt Y.WidgetStdMod
                    //
                    if (Y.Lang.isValue(this.get("action"))) {
                        this._initial_action = this.get("action");
                        this.set("action", null);
                    }
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
                    this.on(
                        "actionChange",
                        Y.bind( this._onActionChange, this )
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
                    if (! Y.Lang.isValue(this._initial_action)) {
                        this._initial_action = this._getDefaultAction();
                    }

                    //
                    // wrapping this so that we can call it separately later,
                    // calling syncUI() directly was causing issues with how
                    // WidgetStdMod handles the BODY node
                    //
                    this._MySyncUI();
                },

                _MySyncUI: function () {
                    Y.log(Clazz.NAME + "::_MySyncUI");

                    this._title_node.setContent( this.get("title") );

                    Y.log("actions: " + Y.Object.keys(this.get("actions")));
                    if (Y.Object.keys(this.get("actions")).length > 1) {
                        Y.each(
                            this.get("actions"),
                            function (v, k, obj) {
                                Y.log(Clazz.NAME + "::_MySyncUI - adding action button: " + v.label);
                                var button = new Y.Button (
                                    {
                                        render:   this._action_buttons_node,
                                        label:    v.label,
                                        callback: Y.bind(
                                            function () {
                                                Y.log(Clazz.NAME + "::_MySyncUI - button callback: " + k);
    
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

                    if (Y.Lang.isValue(this.get("url"))) {
                        // TODO: need to wire in change for polling interval,
                        //       and/or detach/attach of other handler(s)
                        if (this.get("polling_is_active") && this.get("polling_interval") > 0) {
                            Y.log(Clazz.NAME + "::_MySyncUI - starting polling");
                            this._initTimer();
                        }
                    }

                    if (Y.Lang.isValue(this._initial_action)) {
                        Y.log(Clazz.NAME + "::_MySyncUI - setting initial action: " + this._initial_action);
                        this.set("action", this._initial_action);
                        this._initial_action = null;
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

                //
                // prevent switching to an action that doesn't have any corresponding data
                // basically stall it, issue a refresh if possible, and have the action
                // loaded after the refresh finishes
                //
                _onActionChange: function (e) {
                    Y.log(Clazz.NAME + "::_onActionChange");
                    Y.log(Clazz.NAME + "::_onActionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_onActionChange - e.newVal: " + e.newVal);
                    var action_key = e.newVal;

                    //
                    // we set the action to null at times on purpose, we should allow that
                    // since it is obviously not a check against data, it may be the case
                    // that it would be used to load up a default "child" that just displays
                    // a loading message or the like
                    //
                    if (Y.Lang.isValue(action_key)) {
                        var action_data = this.get("actions")[action_key];
                        Y.log(Clazz.NAME + "::_onActionChange - action_data: " + Y.dump(action_data));

                        if (! action_data) {
                            if (Y.Lang.isValue(this.get("url"))) {
                                // stop the setting of the attribute's value
                                e.preventDefault();

                                this._pending_action = action_key;
                                Y.log(Clazz.NAME + "::_onActionChange - set _pending_action:: " + this._pending_action);

                                Y.log(Clazz.NAME + "::_onActionChange - refreshing data");
                                this._refreshData();
                            }
                            else {
                                Y.log(Clazz.NAME + "::_onActionChange - can't set action: no data found (" + action_key + ")", "error");
                                // TODO: upate in UI
                            }
                        }
                    }
                },

                _afterActionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterActionChange");
                    Y.log(Clazz.NAME + "::_afterActionChange - e.prevVal: " + e.prevVal);
                    Y.log(Clazz.NAME + "::_afterActionChange - e.newVal: " + e.newVal);
                    var prev_action_key = e.prevVal;

                    if (Y.Lang.isValue(prev_action_key)) {
                        var prev_cache_entry = this.cache.retrieve(prev_action_key);
                        if (prev_cache_entry) {
                            Y.log(Clazz.NAME + "::_afterActionChange - hiding: " + prev_cache_entry.response);
                            prev_cache_entry.response.hide();
                        }
                    }

                    var action_key = e.newVal;
                    if (Y.Lang.isValue(action_key)) {
                        var cache_entry = this.cache.retrieve(action_key);;
                        Y.log(Clazz.NAME + "::_afterActionChange - cache_entry: " + Y.dump(cache_entry));

                        var child;

                        if (! Y.Lang.isValue(cache_entry)) {
                            this._uiSetFillHeight( Y.WidgetStdMod.BODY );

                            var action_data = this.get("actions")[action_key];
                            Y.log(Clazz.NAME + "::_afterActionChange - action_data: " + Y.dump(action_data));

                            var body_node = this.getStdModNode( Y.WidgetStdMod.BODY );

                            var region    = body_node.get("region");
                            Y.log(Clazz.NAME + "::_afterActionChange - body region: " + Y.dump(region));

                            action_data.renderer.config.render          = body_node;
                            action_data.renderer.config.advisory_width  = region.width;
                            action_data.renderer.config.advisory_height = region.height;

                            child = Y.IC.Renderer.buildContent( action_data.renderer );
                            Y.log(Clazz.NAME + "::_afterActionChange - child from new: " + child);

                            this.add(child);
                            Y.log(Clazz.NAME + "::_afterActionChange - child added: " + child);

                            this.cache.add(action_key, child);
                            Y.log(Clazz.NAME + "::_afterActionChange - child cached: " + child);
                        }
                        else {
                            child = cache_entry.response;
                            Y.log(Clazz.NAME + "::_afterActionChange - child from cache: " + child);
                        }

                        Y.log(Clazz.NAME + "::_afterActionChange - showing child: " + child);
                        child.show();
                    }
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
                    Y.log(Clazz.NAME + "::_onRequestSuccess - _pending_action: " + this._pending_action);

                    //
                    // if there isn't a pending action store off the current action
                    // so that it gets properly restored after parsing the data
                    //
                    if (! Y.Lang.isValue(this._pending_action)) {
                        this._pending_action = this.get("action");
                        Y.log(Clazz.NAME + "::_onRequestSuccess - _pending_action now: " + this._pending_action);
                    }
                    this.set("action", null);

                    // TODO: this could be attached to a handler on "actions"
                    this._action_buttons_node.setContent("");

                    // TODO: this should be handled by a removeChild handler that clears the cached record
                    //       but at least for the moment we always clear them all and cache doesn't provide
                    //       an easy API method for removing a single cache record
                    //       http://yuilibrary.com/projects/yui3/ticket/2529662
                    //
                    this.cache.flush();

                    this.removeAll();

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

                        var set_action;
                        if (Y.Lang.isValue(this._pending_action)) {
                            Y.log(Clazz.NAME + "::_onRequestSuccess - setting action from pending action: " + this.get("action") + ", " + this._pending_action);
                            set_action = this._pending_action;
                            this._pending_action = null;
                        }
                        else {
                            // in the case of no pending action that means that one
                            // has not been specifically requested and there wasn't
                            // a previous one, so we should find the default and
                            // use it
                            set_action = this._getDefaultAction();
                        }
                        if (Y.Lang.isValue(set_action)) {
                            this.set("action", set_action);
                        }

                        this._MySyncUI();

                        this._mesg_node.setContent("Last Updated: " + new Date ());
                    }
                    else {
                        this._mesg_node.setContent("Last Tried: " + new Date () + " (No data in response)");
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");

                    this._mesg_node.setContent("Last Tried: " + new Date () + " (Request failed: "  + response.status + " - " + response.statusText + ")");
                },

                _getDefaultAction: function () {
                    Y.log(Clazz.NAME + "::_getDefaultAction");
                    var return_value;

                    var found = Y.some(
                        this.get("actions"),
                        function (v, k, o) {
                            if (Y.Lang.isValue(v.is_default) && v.is_default) {
                                return_value = k;
                                return true;
                            }
                        }
                    );
                    if (! found) {
                        if (Y.Lang.isValue(this.get("actions").DetailView)) {
                            return_value = "DetailView";
                        }
                        else {
                            return_value = Y.Object.keys(this.get("actions"))[0];
                        }
                    }

                    return return_value;
                }
            },
            {
                ATTRS: {
                    // needed this to make sure the body node exists
                    bodyContent: {
                        value: ""
                    },

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
                        value: {},
                        validator: Y.Lang.isObject
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
