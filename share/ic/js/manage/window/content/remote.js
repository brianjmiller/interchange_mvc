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
                _last_updated:        null,
                _last_tried:          null,

                // _data_url should be set in the initializer of the subclass
                _data_url:            null,

                // reference of the object that makes up the content
                _built_data:          null,

                // action here is just a default suggestion that gets provided to
                // the underlying content, since we don't control the underlying
                // content's actions if that content already exists this will get
                // ignored
                _suggested_action: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._suggested_action = config.action;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._last_updated        = null;
                    this._last_tried          = null;

                    this._data_url            = null;
                    this._built_data.destroy();
                    this._built_data          = null;

                    this._suggested_action    = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    Clazz.superclass.renderUI.apply(this, arguments);

                    // make sure that the body node exists
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

                    // TODO: can/should this be done by a watcher on render?
                    this.fire("update_data");
                },

                setAction: function (action) {
                    Y.log(Clazz.NAME + "::setAction");
                    Y.log(Clazz.NAME + "::setAction - action: " + action);

                    this._suggested_action = action;

                    //
                    // we can be sure that the implementation of data gotten for the remotes
                    // is consistent such that we can do inspection of the results to set 
                    // the action appropriately
                    //
                    // for now at least _built_data will always be a tile that we can set 
                    // an action directly on
                    //
                    if (this._built_data) {
                        Y.log(Clazz.NAME + "::setAction - _built_data: " + this._built_data);

                        this._built_data.set("action", action);
                    }
                },

                _onUpdateData: function () {
                    Y.log(Clazz.NAME + "::_onUpdateData");

                    this._last_tried = new Date ();

                    // TODO: set a loading spinner
                    this.set("bodyContent", "Requesting data from server...");

                    // TODO: protect against more than one call at once
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

                        return;
                    }
                    if (new_data) {
                        Y.log(Clazz.NAME + "::_onRequestSuccess - new_data: " + Y.dump(new_data));

                        var settings;

                        if (Y.Lang.isValue(new_data.renderer)) {
                            settings = new_data.renderer;
                        }
                        else {
                            settings = new_data;
                        }

                        if (Y.Lang.isString(new_data)) {
                            this.set("bodyContent", new_data);
                        }
                        else {
                            this.set("bodyContent", "");

                            var body_node = this.getStdModNode( Y.WidgetStdMod.BODY );

                            var region = body_node.get("region");
                            Y.log(Clazz.NAME + "::_onRequestSuccess - region.width: " + region.width);
                            Y.log(Clazz.NAME + "::_onRequestSuccess - region.height: " + region.height);

                            settings.config.render          = body_node;
                            settings.config.advisory_width  = region.width;
                            settings.config.advisory_height = region.height;

                            var my_action = this._suggested_action;
                            if (Y.Lang.isValue(my_action) && my_action !== "") {
                                settings.config.action = my_action;
                            }

                            this._built_data = Y.IC.Renderer.buildContent(settings);
                        }

                        this._last_updated = new Date ();
                    }
                    else {
                        this.set("bodyContent", "No data in response");
                    }
                },

                _onRequestFailure: function (txnId, response) {
                    Y.log(Clazz.NAME + "::_onRequestFailure");

                    this.set("bodyContent", "Request failed" + " (" + response.status + " - " + response.statusText + ")");
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
