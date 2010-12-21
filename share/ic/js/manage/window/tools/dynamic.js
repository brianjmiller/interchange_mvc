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
    "ic-manage-window-tools-dynamic",
    function(Y) {
        var Clazz = Y.namespace("IC.ManageTool").Dynamic = Y.Base.create(
            "ic_manage_tools_dynamic",
            Y.IC.ManageTool.Base,
            [ Y.WidgetStdMod ],
            {
                _data_url:     null,
                _last_updated: null,
                _last_tried:   null,
                _timer:        null,

                _footer_node:  null,
                _button_node:  null,
                _mesg_node:    null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer - update_interval: " + this.get("update_interval"));
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Y.log(Clazz.NAME + "::renderUI - height: " + this.get("height"));

                    // TODO: add back in buttons for refresh and toggling active
                    //       which amounts to how tile works so it may make sense
                    //       to move all of that to a plugin instead
                    this._button_node = Y.Node.create('<div></div>');
                    this._refresh_button = new Y.Button (
                        {
                            render:   this._button_node,
                            label:    "Refresh",
                            callback: Y.bind(
                                function () {
                                    Y.log(Clazz.NAME + "::renderUI - refresh button callback");
                                    this.getStdModNode( Y.WidgetStdMod.BODY ).setContent("Manual Refresh...");
                                    this.fire("update_data");
                                },
                                this
                            )
                        }
                    );

                    this._mesg_node = Y.Node.create('<div>Initial Load: ' + new Date () + '</div>');
                    this._mesg_node.addClass("micro");

                    this._footer_node = Y.Node.create('<div></div>');
                    this._footer_node.append(this._button_node);
                    this._footer_node.append(this._mesg_node);

                    this.set("footerContent", this._footer_node);
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

                    this.getStdModNode( Y.WidgetStdMod.FOOTER ).addClass("centered");

                    this.fire("update_data");
                    if (this.get("update_interval") > 0) {
                        this._initTimer();
                    }
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
                    this._last_tried = new Date ();

                    this._mesg_node.setContent("Requesting data from server...");

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

                    this._mesg_node.setContent("Received response...");

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        this._mesg_node.setContent("Last Try: " + this._last_tried + "<br />" + e);

                        return;
                    }
                    if (new_data) {
                        this._last_updated = new Date ();

                        this._handleNewData(new_data);

                        this._mesg_node.setContent("Last Update: " + this._last_updated);
                    }
                    else {
                        this._handleEmptyData();
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");
                    Y.log(Clazz.NAME + "::_onRequestFailure - response: " + Y.dump(response));

                    this._mesg_node.setContent("Last Try: " + this._last_tried);
                },

                _handleNewData: function (new_data) {
                    this.set("bodyContent", Y.dump(new_data));
                },

                _handleEmptyData: function () {
                    this.set("bodyContent", "No data received.");
                }
            },
            {
                ATTRS: {
                    bodyContent: {
                        value: ""
                    },
                    footerContent: {
                        value: ""
                    },
                    update_interval: {
                        // in number of seconds
                        value:     0,
                        validator: Y.Lang.isNumber
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            //"ic-manage-window-tools-dynamic-css",
            "ic-manage-window-tools-base",
            "widget-stdmod",
            "gallery-button"
        ]
    }
);
