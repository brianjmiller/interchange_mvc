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
    "ic-manage-window-content-function-action-list-record",
    function(Y) {
        var ManageWindowContentFunctionActionListRecord;

        ManageWindowContentFunctionActionListRecord = function (config) {
            ManageWindowContentFunctionActionListRecord.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunctionActionListRecord,
            {
                NAME: "ic_manage_window_content_function_action_list_record",
                ATTRS: {
                    pk: {
                        value: null
                    },
                    action: {
                        value: null
                    },
                    header_node: {
                        value: null
                    },
                    display_node: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentFunctionActionListRecord,
            Y.Widget,
            {
                _caller:                null,
                _meta:                  null,
                _pending_action:        null,
                _action_cache:          null,
                _action_button_group:   null,

                initializer: function (config) {
                    //Y.log("manage_window_content_function_action_list_record::initializer");
                    //Y.log("manage_window_content_function_action_list_record::initializer: " + Y.dump(config));
                    this._caller       = config._caller;
                    this._action_cache = {
                        _message: {
                            button: 0
                        }
                    };

                    this._action_cache._message.content_node = Y.Node.create('<div class="list_record_message_action_node">Initializing record...</div>');

                    this.set("header_node", Y.Node.create('<div class="list_record_header_node yui3-g"><div class="header_node_description yui3-u-1-2">Record Description</div><div class="header_node_buttons yui3-u-1-2"></div></div>'));
                    this.set("display_node", Y.Node.create('<div class="list_record_display_node"></div>'));

                    //Y.log("manage_window_content_function_action_list_record::initializer - display_node: " + this.get("display_node"));
                    this.render( this.get("display_node") );
                },

                renderUI: function () {
                    //Y.log("manage_window_content_function_action_list_record::renderUI");
                    //Y.log("manage_window_content_function_action_list_record::renderUI - contentBox: " + this.get("contentBox"));

                    this.get("contentBox").setContent(this._action_cache._message.content_node);
                },

                bindUI: function () {
                    //Y.log("manage_window_content_function_action_list_record::bindUI");
                    this.on(
                        "get_meta_data",
                        Y.bind( this._onGetMetaData, this )
                    );
                    this.on(
                        "actionChange",
                        Y.bind( this._onActionChange, this)
                    );
                    this.after(
                        "actionChange",
                        Y.bind( this._afterActionChange, this)
                    );
                },

                syncUI: function () {
                    //Y.log("manage_window_content_function_action_list_record::syncUI");
                    this.set("action", "_message");

                    if (this.get("pk")) {
                        this.fire("get_meta_data");
                    }
                },

                _onGetMetaData: function () {
                    //Y.log("manage_window_content_function_action_list_record::_onGetMetaData");
                    this._action_cache._message.content_node.setContent("Getting meta data");

                    var url = "/manage/" + this._caller._caller.get("manage_class") + "/object_ui_meta_struct?_format=json&" + Y.QueryString.stringify(this.get("pk"));
                    //Y.log("manage_window_content_function_action_list_record::_onGetMetaData - url: " + url);

                    Y.io(
                        url,
                        {
                            on: {
                                success: Y.bind(this._parseMetaData, this),
                                failure: Y.bind(
                                    function (txnId, response) {
                                        //Y.log("manage_window_content_function_action_list_record::_onGetMetaData - Failed to get object meta data", "error");
                                    },
                                    this
                                )
                            }
                        }
                    );
                },

                _parseMetaData: function (txnId, response) {
                    //Y.log("manage_window_content_function_action_list_record::_parseMetaData");
                    this._action_cache._message.content_node.setContent("parsing meta data");

                    try {
                        this._meta = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        // TODO: improve handling
                        //Y.log("manage_window_content_function_action_list_record::_parseMetaData - Can't parse JSON: " + e, "error");

                        this._action_cache._message.content_node.setContent("Meta data failed to parse: " + e);

                        return;
                    }
                    if (this._meta) {
                        //Y.log("manage_window_content_function_action_list_record::_parseMetaData - Meta data loaded");

                        this._action_cache._message.content_node.setContent("Meta data loaded");

                        var action_buttons = [];
                        Y.each(
                            this._meta.actions,
                            function (v, k, o) {
                                this._action_cache[k] = {
                                    description: v.label
                                };

                                var button_config = {
                                    label:    v.label,
                                    callback: Y.bind(
                                        this._onActionButtonClick,
                                        this,
                                        k
                                    )
                                };
                                var button = new Y.ButtonToggle (button_config);

                                this._action_cache[k].button = button;

                                action_buttons.push(button);
                            },
                            this
                        );

                        if (action_buttons.length) {
                            this._action_button_group = new Y.ButtonGroup (
                                {
                                    label:          "",
                                    children:       action_buttons,
                                    render:         this.get("header_node").one("div.header_node_buttons"),
                                    alwaysSelected: true
                                }
                            );
                            // TODO: need to key this off the specific requested action
                            this._action_button_group.selectChild(0);
                        }

                        if (this._pending_action) {
                            //Y.log("manage_window_content_function_action_list_record::_parseMetaData - restoring pending action");

                            this.set("action", this._pending_action);
                            this._pending_action = null;
                        }
                    }
                },

                _onActionChange: function (e) {
                    //Y.log("manage_window_content_function_action_list_record::_onActionChange");
                    //Y.log("manage_window_content_function_action_list_record::_onActionChange - e.newVal: " + e.newVal);

                    if (! this._meta && e.newVal !== "_message") {
                        //Y.log("manage_window_content_function_action_list_record::_onActionChange - stopping action to load meta: " + e.newVal);
                        e.preventDefault();

                        this._pending_action = e.newVal;

                        // TODO: need to check for whether meta data is being requested and if not to request it
                        return;
                    }
                    //Y.log("manage_window_content_function_action_list_record::_onActionChange - continuing set of action: " + e.newVal);
                },

                _afterActionChange: function (e) {
                    //Y.log("manage_window_content_function_action_list_record::_afterActionChange");

                    var action = this.get("action");
                    //Y.log("manage_window_content_function_action_list_record::_afterActionChange - action: " + this.get("action"));

                    if (! this._action_cache[action].content_node) {
                        this._action_cache[action].content_node = Y.Node.create('<div class="record_action_' + action + '_node">I am the ' + action + " display node for record: " + Y.dump(this.get("pk")) + "</div>");

                        var action_meta = this._meta.actions[action].meta;

                        Y.log("manage_window_content_function_action_list_record::_afterActionChange - prototype: " + action_meta._prototype);
                        var _constructor = Y.IC.Renderer.getConstructor(action_meta._prototype);

                        var _constructor_config = action_meta._prototype_config || {};
                        _constructor_config._caller = this;

                        var renderer = new _constructor ( _constructor_config );
                        renderer.render();

                        this._action_cache[action].content_node.setContent( renderer.get("display_node") );
                    }

                    this.get("header_node").one("div.header_node_description").setContent(this._action_cache[action].description);
                    this.get("contentBox").setContent(this._action_cache[action].content_node);
                    //Y.log("manage_window_content_function_action_list_record::_afterActionChange done");
                },

                _onActionButtonClick: function (code) {
                    Y.log("manage_window_content_function_action_list_record::_onActionButtonClick: " + code);
                    this.set("action", code);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentFunctionActionListRecord = ManageWindowContentFunctionActionListRecord;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-function-action-list-record-css",
            "widget",
            "querystring",
            "gallery-button-group",
            "gallery-button",
            "gallery-button-toggle",
            "ic-renderer"
        ]
    }
);
