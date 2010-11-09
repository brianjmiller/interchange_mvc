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
    "ic-manage-window-content-dashboard",
    function(Y) {
        var ManageWindowContentDashboard;

        var Lang = Y.Lang;

        var BUTTON_IS_ACTIVE_TOGGLE_ON  = 'Auto Update: On';
        var BUTTON_IS_ACTIVE_TOGGLE_OFF = 'Auto Update: Off';

        ManageWindowContentDashboard = function (config) {
            ManageWindowContentDashboard.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentDashboard,
            {
                NAME: "ic_manage_content_dashboard",
                ATTRS: {
                    description: {
                        value: "Dashboard"
                    },
                    layout: {
                        value: "full"
                    },

                    update_interval: {
                        // in number of seconds
                        value:     "60",
                        validator: Lang.isNumber
                    },
                    last_updated: {
                        value: null
                    },
                    is_active: {
                        value:     true,
                        validator: Lang.isBoolean 
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentDashboard,
            Y.IC.ManageWindowContentBase,
            {
                _last_updated:       null,
                _last_tried:         null,
                _timer:              null,
                _data_url:           null,
                _active_when_hidden: null,

                initializer: function (config) {
                    Y.log("manage_window_content_dashboard::initializer");
                    Y.log("manage_window_content_dashboard::initializer - update_interval: " + this.get("update_interval"));
                    Y.log("manage_window_content_dashboard::initializer - last_updated: " + this.get("last_updated"));

                    this._data_url = "/manage/widget/dashboard/data?_format=json";
                    Y.log("manage_window_content_dashboard::initializer - _data_url: " + this._data_url);

                    this.on(
                        "update_data",
                        Y.bind( this._onUpdateData, this )
                    );
                    this.on(
                        "request_data",
                        Y.bind( this._onRequestData, this )
                    );

                    this.set(
                        "actions",
                        [
                            {
                                label:    "Refresh",
                                callback: Y.bind(
                                    this._onUpdateData,
                                    this
                                )
                            },
                            {
                                label:     (this.get("is_active") ? BUTTON_IS_ACTIVE_TOGGLE_ON : BUTTON_IS_ACTIVE_TOGGLE_OFF),
                                add_class: "dashboard-toggle-active-button",
                                callback:  Y.bind(
                                    this.toggleActive,
                                    this
                                )
                            }
                        ]
                    );

                    this.render();
                },

                renderUI: function () {
                    Y.log("manage_window_content_dashboard::renderUI");
                    Y.log("manage_window_content_dashboard::renderUI - boundingBox: " + this.get("boundingBox"));
                    this._pieces = {
                        full_center_body: this.get("boundingBox")
                    };
                },

                syncUI: function () {
                    this._setInitialContent();
                },

                _setInitialContent: function () {
                    Y.log("manage_window_content_dashboard::_setInitialContent");
                    this.get("contentBox").setContent("Loading data from server");
                },

                _initTimer: function () {
                    this._timer = Y.later(
                        (this.get("update_interval") * 1000),
                        this,
                        function () {
                            this.fire('update_data');
                        },
                        null,
                        true
                    );
                },

                _onShow: function (e) {
                    //Y.log("manage_window_content_dashboard::_onShow");
                    //Y.log("manage_window_content_dashboard::_onShow - e: " + Y.dump(e));

                    if (Y.Lang.isValue(this._active_when_hidden) && this._active_when_hidden) {
                        if (! this.get("is_active")) {
                            this.toggleActive();
                        }
                    }

                    if (this.get("is_active") && this.get("update_interval")) {
                        this.fire("update_data");

                        this._initTimer();
                    }

                    Y.IC.ManageWindowContentDashboard.superclass._onShow.apply(this, arguments);
                },

                _onForceReload: function (e) {
                    Y.log("manage_window_content_dashboard::_onForceReload");
                    //Y.log("manage_window_content_dashboard::_onForceReload - e: " + Y.dump(e));

                    this._setInitialContent();

                    if (this._timer) {
                        this._timer.cancel();
                    }

                    this.fire("show");
                },

                _onHide: function (e) {
                    //Y.log("manage_window_content_dashboard::_onHide");
                    //Y.log("manage_window_content_dashboard::_onHide - e: " + Y.dump(e));

                    this._active_when_hidden = this.get("is_active");
                    if (this.get("is_active")) {
                        this.toggleActive();
                    }

                    Y.IC.ManageWindowContentDashboard.superclass._onHide.apply(this, arguments);
                },

                _onUpdateData: function (e) {
                    Y.log("manage_window_content_dashboard::_onUpdateData");

                    this.fire("request_data");
                },

                _onRequestData: function (e) {
                    Y.log("manage_window_content_dashboard::_onRequestData");

                    // TODO: set a loading indicator
                    // TODO: protect against more than one call at once
                    var current = new Date();
                    this._last_tried = current;

                    this.set("message", "Requesting data from server...");

                    Y.io(
                        this._data_url,
                        {
                            on: {
                                success: Y.bind(this._onRequestSuccess, this),
                                failure: Y.bind(this._onRequestFailure, this)
                            }
                        }
                    );
                },

                _onRequestSuccess: function (txnId, response) {
                    Y.log("manage_window_content_dashboard::_onRequestSuccess");
                    Y.log("manage_window_content_dashboard::_onRequestSuccess - response: " + Y.dump(response));

                    this.set("message", "Received response...");

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        // TODO: improve handling
                        Y.log("manage_window_content_dashboard::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        this.set("message", "Last Try: " + this._last_tried);
                        //this._pieces.full_center_body.setContent("Meta data failed to parse...." + e);

                        return;
                    }
                    if (new_data) {
                        var current = new Date();
                        this._last_updated = current;

                        // TODO: this needs to be vastly improved to not recreate all the content each time
                        var renderer_constructor = Y.IC.Renderer.getConstructor(new_data.renderer_type);
                        var renderer_config      = new_data.renderer_config;

                        renderer_config._caller = this;

                        var renderer = new renderer_constructor (renderer_config);
                        renderer.render();

                        this.set("message", "Last Update: " + this._last_updated);
                        this.get("contentBox").setContent(renderer.get("boundingBox"));
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log("manage_window_content_dashboard::_onRequestFailure");
                    Y.log("manage_window_content_dashboard::_onRequestFailure - response: " + Y.dump(response));

                    this.set("message", "Last Try: " + this._last_tried);
                },

                toggleActive: function (e) {
                    Y.log("manage_window_content_dashboard::toggleActive");

                    var button;
                    if (this._containing_pane) {
                        button = this._containing_pane._header_to.one("span.dashboard-toggle-active-button");
                        Y.log("manage_window_content_dashboard::toggleActive - button: " + button);
                    }

                    var button_label = "";
                    if (this.get("is_active")) {
                        this.set("is_active", false);
                        button_label = BUTTON_IS_ACTIVE_TOGGLE_OFF;
                        this._timer.cancel();
                    }
                    else {
                        this.set("is_active", true);
                        button_label = BUTTON_IS_ACTIVE_TOGGLE_ON;
                        this._initTimer();
                    }

                    // this is a hack because of how the actions are handled, rather than being
                    // cached and re-shown, they are re-built so we need to set the state in
                    // the action itself
                    this.get("actions")[1].label = button_label;

                    if (button && button_label !== "") {
                        button.setContent(button_label);
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentDashboard = ManageWindowContentDashboard;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-dashboard-css",
            "ic-manage-window-content-base"
        ]
    }
);
