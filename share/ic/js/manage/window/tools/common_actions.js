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
    "ic-manage-window-tools-common_actions",
    function(Y) {
        var Clazz = Y.namespace("IC.ManageTool").CommonActions = Y.Base.create(
            "ic_manage_tools_common_actions",
            Y.IC.ManageTool.Base,
            [ Y.WidgetStdMod ],
            {
                _data_url:     null,
                _last_updated: null,
                _last_tried:   null,
                _timer:        null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer - update_interval: " + this.get("update_interval"));

                    this._data_url = "/manage/widget/tools/common_actions/data?_format=json";
                    Y.log(Clazz.NAME + "::initializer - _data_url: " + this._data_url);
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Y.log(Clazz.NAME + "::renderUI - height: " + this.get("height"));

                    // TODO: add back in buttons for refresh and toggling active
                    //       which amounts to how tile works so it may make sense
                    //       to move all of that to a plugin instead
                    this.set("bodyContent", "");
                    this.set("footerContent", "");
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");
                    this.on(
                        "update_data",
                        Y.bind( this._onUpdateData, this )
                    );
                    this.on(
                        "request_data",
                        Y.bind( this._onRequestData, this )
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    this.getStdModNode( Y.WidgetStdMod.BODY ).addClass("centered");
                    this.getStdModNode( Y.WidgetStdMod.FOOTER ).addClass("centered");
                    this.getStdModNode( Y.WidgetStdMod.FOOTER ).addClass("micro");

                    this.fire("update_data");
                    this._initTimer();
                },

                _initTimer: function () {
                    this._timer = Y.later(
                        (this.get("update_interval") * 1000),
                        this,
                        function () {
                            this.fire("update_data");
                        },
                        null,
                        true
                    );
                },

                _onUpdateData: function (e) {
                    //Y.log(Clazz.NAME + "::_onUpdateData");

                    this.fire("request_data");
                },

                _onRequestData: function (e) {
                    //Y.log(Clazz.NAME + "::_onRequestData");

                    // TODO: set a loading indicator
                    // TODO: protect against more than one call at once
                    var current = new Date();
                    this._last_tried = current;

                    this.set("footerContent", "Requesting data from server...");

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
                    //Y.log(Clazz.NAME + "::_onRequestSuccess");
                    //Y.log(Clazz.NAME + "::_onRequestSuccess - response: " + Y.dump(response));

                    this.set("footerContent", "Received response...");

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        this.set("footerContent", "Last Try: " + this._last_tried + "<br />" + e);

                        return;
                    }
                    if (new_data) {
                        var current = new Date();
                        this._last_updated = current;
                        this.set("bodyContent", "");

                        if (Y.Lang.isValue(new_data.buttons) && new_data.buttons.length > 0) {
                            Y.each(
                                new_data.buttons,
                                function (config, i, a) {
                                    var button = new Y.Button (
                                        {
                                            render:   this.getStdModNode(Y.WidgetStdMod.BODY),
                                            label:    config.label,
                                            width:    "160px",
                                            callback: Y.bind(
                                                function () {
                                                    this._window.fire(
                                                        "contentPaneShowContent",
                                                        config.kind,
                                                        config.clazz,
                                                        config.action,
                                                        config.args
                                                    );
                                                },
                                                this
                                            )
                                        }
                                    );
                                },
                                this
                            );
                        }

                        this.set("footerContent", "Last Update: " + this._last_updated);
                    }
                    else {
                        this.set("bodyContent", "No data received.");
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");
                    Y.log(Clazz.NAME + "::_onRequestFailure - response: " + Y.dump(response));

                    this.set("footerContent", "Last Try: " + this._last_tried);
                }
            },
            {
                ATTRS: {
                    update_interval: {
                        // in number of seconds
                        value:     "15",
                        validator: Y.Lang.isNumber
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-common_actions-css",
            "ic-manage-window-tools-base",
            "widget-stdmod",
            "gallery-button"
        ]
    }
);
