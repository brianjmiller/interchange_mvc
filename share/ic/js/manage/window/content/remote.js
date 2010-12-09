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
    "ic-manage-window-content-remote",
    function (Y) {
        var Clazz = Y.namespace("IC").ManageWindowContentRemote = Y.Base.create(
            "ic_manage_window_content_remote",
            Y.IC.ManageWindowContentBase,
            [],
            {
                _data_url:         null,
                _last_updated:     null,
                _last_tried:       null,

                _built_data:       null,

                // action here is just a default suggestion that gets provided to
                // the underlying content, since we don't control the underlying
                // content's actions if that content already exists this will get
                // ignored
                _suggested_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._built_data.destroy();
                    this._built_data       = null;

                    this._data_url         = null;
                    this._last_updated     = null;
                    this._last_tried       = null;
                    this._suggested_action = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    Clazz.superclass.renderUI.apply(this, arguments);

                    this.set("footerContent", "Remote Footer");
                    this.set("bodyContent", "Remote Body");
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    Clazz.superclass.bindUI.apply(this, arguments);

                    this.on(
                        "update_data",
                        Y.bind( this._onUpdateData, this )
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    Clazz.superclass.syncUI.apply(this, arguments);

                    this.fire("update_data");
                },

                setAction: function (action) {
                    Y.log(Clazz.NAME + "::setAction");
                    Y.log(Clazz.NAME + "::setAction - action: " + action);

                    this._suggested_action = action;
                },

                _onUpdateData: function () {
                    Y.log(Clazz.NAME + "::_onUpdateData");

                    // TODO: set a loading indicator
                    // TODO: protect against more than one call at once
                    var current = new Date();
                    this._last_tried = current;

                    this.set("footerContent", "Loading...");
                    this.set("bodyContent", "Requesting data from server...");

                    // TODO: URL building needs to take domain, protocol, and path prefix into account
                    Y.io(
                        this._data_url,
                        {
                            on: {
                                success: Y.bind(this._onRequestSuccess, this),
                                failure: Y.bind(this._onRequestFailure, this)
                            }
                        }
                    );

                    this.set("bodyContent", "Data requested from server...");
                },

                _onRequestSuccess: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestSuccess");
                    Y.log(Clazz.NAME + "::_onRequestSuccess - response: " + Y.dump(response));

                    this.set("bodyContent", "Received response...");

                    var new_data;
                    try {
                        new_data = Y.JSON.parse(response.responseText);
                    }
                    catch (e) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - Can't parse JSON: " + e, "error");

                        this.set("bodyContent", "Can't parse JSON response: " + e);
                        this.set("footerContent", "Last Try: " + this._last_tried);

                        return;
                    }
                    if (new_data) {
                        if (Y.Lang.isValue(new_data.renderer)) {
                            this.set("bodyContent", "");

                            var constructor = Y.IC.Renderer.getConstructor(new_data.renderer.type);

                            //Y.log(Clazz.NAME + "::_onRequetSuccess - BODY region: " + Y.dump(this.getStdModNode( Y.WidgetStdMod.BODY ).get("region")));
                            var body_node = this.getStdModNode( Y.WidgetStdMod.BODY );
                            var region    = body_node.get("region");
                            new_data.renderer.config.render = body_node;
                            new_data.renderer.config.width  = region.width;
                            new_data.renderer.config.height = region.height;

                            var my_action = this._suggested_action;
                            if (Y.Lang.isValue(my_action) && my_action !== "") {
                                new_data.renderer.config.action = my_action;
                            }

                            this._built_data = new constructor (new_data.renderer.config);
                        }
                        else {
                            var content = Y.IC.Renderer.buildContent(new_data);

                            this.set("bodyContent", content);
                        }

                        var current = new Date();
                        this._last_updated = current;

                        this.set("footerContent", "Last Update: " + this._last_updated);
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");

                    this.set("bodyContent", "Request failed");
                    this.set("footerContent", "Last Try: " + this._last_tried + "(" + response.status + " - " + response.statusText + ")");
                }
            },
            {
                ATTRS: {},

                getCacheKey: function (config) {
                    Y.log(Clazz.NAME + "::getCacheKey");
                    Y.log(Clazz.NAME + "::getCacheKey - config: " + Y.dump(config));

                    return "remote-" + config.clazz;
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            //"ic-manage-window-content-remote-css",
            "ic-manage-window-content-base",
            "ic-renderer"
        ]
    }
);
