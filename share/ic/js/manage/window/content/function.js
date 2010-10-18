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
    "ic-manage-window-content-function",
    function(Y) {
        var ManageWindowContentFunction;

        ManageWindowContentFunction = function (config) {
            ManageWindowContentFunction.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunction,
            {
                NAME: "ic_manage_content_function",
                ATTRS: {
                    description: {
                        value: "Function"
                    },
                    layout: {
                        value: "full"
                    },

                    manage_class: {
                        value: null
                    },

                    // setting the current action will cause it to
                    // be loaded into the content areas of the layout
                    // and optionally retrieve any data needed, etc.
                    current_action: {
                        value: null
                    },

                    // store the meta data that describes how this
                    // class should act
                    _meta: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentFunction,
            Y.IC.ManageWindowContentBase,
            {
                // temporary store for action waiting for meta data to load
                _pending_action: null,

                // cache of the action objects
                // for some reason I had to set this to null instead of {}
                // because we weren't ending up with a new, clean object
                // but instead it was using one for all objects of the class
                _action_cache: null,

                _current_action_object: null,

                // list of classes that can be constructed for display in our pane
                _action_constructor_map: {
                    Basic: Y.IC.ManageWindowContentFunctionActionBasic.prototype.constructor,
                    List:  Y.IC.ManageWindowContentFunctionActionList.prototype.constructor
                },

                initializer: function (config) {
                    //Y.log("manage_window_content_function::initializer");
                    //Y.log("manage_window_content_function::initializer" + Y.dump(config));
                    //Y.log("manage_window_content_function::initializer - manage_class: " + this.get("manage_class"));
                    this._action_cache = {};

                    this.on(
                        "request_meta_data",
                        Y.bind( this._onRequestMetaData, this )
                    );
                    this.on(
                        "current_actionChange",
                        Y.bind( this._onCurrentActionChange, this )
                    );
                    this.after(
                        "current_actionChange",
                        Y.bind( this._afterCurrentActionChange, this )
                    );

                    this._pieces = {
                        full_center_body:        Y.Node.create('<div class="function_full_center_body_container"></div>'),
                        h_divided_top_body:      Y.Node.create('<div class="function_h_divided_top_body_container"></div>'),
                        h_divided_center_header: Y.Node.create('<div class="function_h_divided_center_header_container"></div>'),
                        h_divided_center_body:   Y.Node.create('<div class="function_h_divided_center_body_container"></div>')
                    };

                    this.fire('request_meta_data');
                },

                _onShow: function (e) {
                    //Y.log("manage_window_content_function::_onShow: " + this);
                    //Y.log("manage_window_content_function::_onShow - e: " + Y.dump(e));

                    var action = e.details[0];

                    if (action) {
                        this.set("current_action", action);
                    }
                    else {
                        Y.log("manage_window_content_function::_onShow - need default action");
                        this.set("current_action", "_default");
                    }

                    Y.IC.ManageWindowContentFunction.superclass._onShow.apply(this, arguments);
                },

                _onForceReload: function (e) {
                    //Y.log("manage_window_content_function::_onForceReload");
                    //Y.log("manage_window_content_function::_onShow - e: " + Y.dump(e));

                    this._action_cache          = {};
                    this._current_action_object = null;
                    this.set("_meta", null);

                    this.fire("request_meta_data");

                    // TODO: need to set current action to action received
                    var action = e.details[0];

                    if (action) {
                        this.set("current_action", action);
                    }
                    else {
                        Y.log("manage_window_content_function::_onForceReload - need default action");
                        this.set("current_action", "_default");
                    }
                },

                _onRequestMetaData: function (e) {
                    //Y.log("manage_window_content_function::_onRequestMetaData");
                    this.set("description", "Loading class...");

                    // action cache is cleared because the action constructors
                    // use the meta data to get set up, which could have potentially
                    // changed after this fires the request meta data
                    this.set("_action_cache", null);

                    // TODO: URL building needs to take domain, protocol, and path prefix into account
                    var url = "/manage/" + this.get("manage_class") + "/ui_meta_struct?_format=json";
                    //Y.log("manage_window_content_function::_onRequestMetaData - url: " + url);

                    Y.io(
                        url,
                        {
                            sync: false,
                            on: {
                                success: Y.bind(this._parseMetaData, this),
                                failure: Y.bind(
                                    function (txnId, response) {
                                        Y.log("manage_window_content_function::_onRequestMetaData - Failed to get function meta data", "error");
                                        this.set("description", "Meta data load failed");

                                        this._pieces.full_center_body.setContent("Could not load meta data");
                                    },
                                    this
                                )
                            }
                        }
                    );
                },

                _parseMetaData: function (txnId, response) {
                    //Y.log("manage_window_content_function::_parseMetaData");
                    try {
                        this.set("_meta", Y.JSON.parse(response.responseText));
                    }
                    catch (e) {
                        // TODO: improve handling
                        Y.log("manage_window_content_function::_parseMetaData - Can't parse JSON: " + e, "error");

                        this._pieces.full_center_body.setContent("Meta data failed to parse....");

                        return;
                    }
                    if (this.get("_meta")) {
                        //Y.log("manage_window_content_function::_parseMetaData - Meta data loaded");

                        // Set our description based on our meta data which will set the pane's header
                        this.set("description", this.get("_meta").model_name_plural);

                        var action_buttons = [];
                        Y.each(
                            this.get("_meta").actions,
                            function (v, k, o) {
                                //Y.log("code: " + k);
                                action_buttons.push(
                                    {
                                        label:    v.label,
                                        callback: Y.bind(
                                            this._onActionButtonClick,
                                            this,
                                            k
                                        )
                                    }
                                );
                            },
                            this
                        );
                        this.set("actions", action_buttons);

                        this._pieces.full_center_body.setContent("Meta data loaded....");

                        if (this._pending_action) {
                            //Y.log("manage_window_content_function::_parseMetaData - restoring pending action");

                            this.set("current_action", this._pending_action);
                            this._pending_action = null;
                        }
                    }
                },

                _onCurrentActionChange: function (e) {
                    //Y.log("manage_window_content_function::_onCurrentActionChange");
                    //Y.log("manage_window_content_function::_onCurrentActionChange - e: " + Y.dump(e));

                    //
                    // check for meta data, if exists then just go right ahead,
                    // if doesn't then store the action as a pending action
                    // then when meta data is finished we can load the action
                    //
                    if (! this.get("_meta")) {
                        //Y.log("manage_window_content_function::_onCurrentActionChange - have to wait for meta load");

                        // display a loading message that will later get removed
                        this._pieces.full_center_body.setContent("Loading action meta data....");

                        // stop setting of this action
                        e.preventDefault();

                        // store the value temporarily to be restored by meta success
                        this._pending_action = e.newVal;

                        // TODO: we should check to make sure the meta data is in process of loading
                        //       otherwise we need to initiate loading it

                        return;
                    }

                    //Y.log("manage_window_content_function::_onCurrentActionChange - meta loaded doing default: " + Y.dump(e.newVal));
                },

                _afterCurrentActionChange: function (e) {
                    //Y.log("manage_window_content_function::_afterCurrentActionChange: " + this);
                    //Y.log("manage_window_content_function::_afterCurrentActionChange - action now: " + Y.dump(this.get("current_action")));
                    //Y.log("manage_window_content_function::_afterCurrentActionChange - _action_cache: " + Y.dump(this._action_cache));

                    // TODO: need to pull the content pieces from the cache based on the action
                    //       plus additional args, and toss them in the layout in the right
                    //       position then show the layout that the action uses
                    //
                    //       if the action content doesn't yet exist we need to get the content
                    //       pieces and do whatever is required to load them


                    var _cache_key = this.get("current_action").base;

                    var action_object;
                    if (this._action_cache[_cache_key]) {
                        // TODO: need to use args to set attributes or something on the existing object
                        //       before getting the content so it can take effect, or pass them to an 
                        //       event fired on the action object
                        action_object = this._action_cache[_cache_key];
                    }
                    else {
                        // the action_prototype determines what constructor we need
                        var action_prototype = this.get("_meta").actions[ this.get("current_action").base ]._prototype;
                        //Y.log("manage_window_content_function::_afterCurrentActionChange - action_prototype: " + action_prototype);

                        var _constructor = this._action_constructor_map[action_prototype];

                        action_object = new _constructor (
                            {
                                _caller:  this,
                                settings: this.get("current_action"),
                                meta:     this.get("_meta").actions[ this.get("current_action").base ]
                            }
                        );

                        if (action_object.get("can_cache")) {
                            this._action_cache[_cache_key] = action_object;
                        }
                    }

                    this._current_action_object = action_object;

                    action_object.fire("load");

                    this._loadPieces();

                    this.set("layout", action_object.get("layout"));
                },

                _loadPieces: function (layout) {
                    Y.log("manage_window_content_function::_loadPieces: " + this);
                    var action_layout;
                    if (layout) {
                        action_layout = layout;
                    }
                    else {
                        action_layout = this._current_action_object.get("layout");
                    }
                    //Y.log("manage_window_content_function::_loadPieces - action_layout: " + action_layout);

                    Y.each(
                        this._current_action_object._parts,
                        function (part, k, o) {
                            var piece_id = action_layout + '_' + k;
                            //Y.log("piece_id: " + piece_id + ", " + part);

                            this._pieces[piece_id].setContent( part );
                        },
                        this
                    );
                },

                _onActionButtonClick: function (code) {
                    //Y.log("manage_window_content_function::_onActionButtonClick: " + this);
                    //Y.log("manage_window_content_function::_onActionButtonClick - code: " + code);
                    this.set("current_action", { base: code });
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentFunction = ManageWindowContentFunction;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-base",
            "ic-manage-window-content-function-action-list",
            "node"
        ]
    }
);
