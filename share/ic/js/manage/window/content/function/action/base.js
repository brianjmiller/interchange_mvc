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
    "ic-manage-window-content-function-action-base",
    function(Y) {
        var ManageWindowContentFunctionActionBase; 

        ManageWindowContentFunctionActionBase = function (config) {
            ManageWindowContentFunctionActionBase.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunctionActionBase,
            {
                NAME: "ic_manage_content_function_action_base",
                ATTRS: {
                    settings: {
                        value: null
                    },
                    meta: {
                        value: null
                    },

                    // whether this action should be allowed to be cached
                    // by the function object for quick loading
                    can_cache: {
                        value: true
                    },

                    // currently selected layout that we want displaying our pieces
                    // this gets propagated through the _caller (function object) to
                    // the content pane itself
                    layout: {
                        value: null
                    },

                    part_names: {
                        value: null
                    }
                }
            }
        );
        Y.extend(
            ManageWindowContentFunctionActionBase,
            Y.Base,
            {
                // the function object that is loading the actions, used to place pieces
                // of content that we build/run
                _caller: null,

                _parts: null,

                initializer: function (config) {
                    //Y.log("manage_window_content_function_action_base::initializer");
                    //Y.log("manage_window_content_function_action_base::initializer - _caller" + config._caller);
                    if (config._caller) {
                        this._caller = config._caller;
                    }

                    this._parts = {};

                    this.on(
                        "layoutChange",
                        Y.bind(this._onLayoutChange, this)
                    );
                    this.on(
                        "load",
                        Y.bind(this._onLoad, this)
                    );
                },

                _onLoad: function (e) {
                    //Y.log("manage_window_content_function_action_base::_onLoad");
                    //Y.log("manage_window_content_function_action_base::_onLoad - layout: " + this.get("layout"));
                    this._setFunctionLayout(this.get("layout"));
                },

                _onLayoutChange: function (e) {
                    //Y.log("manage_window_content_function_action_base::_onLayoutChange - e.newVal: " + e.newVal);
                    if (this._caller && this._caller.get("layout") !== e.newVal) {
                        this._setFunctionLayout(e.newVal);
                    }
                },

                _setFunctionLayout: function (layout) {
                    //Y.log("manage_window_content_function_action_base::_setFunctionLayout - layout: " + layout);
                    if (this._caller && layout !== null) {
                        this._caller.set("layout", layout);
                    }
                },

                getBaseURL: function () {
                    //Y.log("manage_window_content_function_action_base::getBaseURL");

                    return "/manage/" + this._caller.get("manage_class") + "/action/" + this.get("settings").base;
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentFunctionActionBase = ManageWindowContentFunctionActionBase;
    },
    "@VERSION@",
    {
        requires: [
            "base-base"
        ]
    }
);
