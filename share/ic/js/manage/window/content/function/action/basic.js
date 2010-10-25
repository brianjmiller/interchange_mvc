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
    "ic-manage-window-content-function-action-basic",
    function(Y) {
        var ManageWindowContentFunctionActionBasic;

        ManageWindowContentFunctionActionBasic = function (config) {
            ManageWindowContentFunctionActionBasic.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunctionActionBasic,
            {
                NAME: "ic_manage_content_function_action_basic",
                ATTRS: {
                    layout: {
                        value: "full"
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentFunctionActionBasic,
            Y.IC.ManageWindowContentFunctionActionBase,
            {
                _content_node: null,
                _content:      null,

                initializer: function (config) {
                    Y.log("manage_window_content_function_action_basic::initializer");
                    Y.log("manage_window_content_function_action_basic::initializer: " + Y.dump(this.get("meta")));

                    this._content_node = Y.Node.create("<div></div>");

                    if (this.get("meta").renderer) {
                        var renderer_meta = this.get("meta").renderer;

                        Y.log("manage_window_content_function_action_basic::initializer - renderer.type: " + renderer_meta.type);
                        var _constructor = Y.IC.Renderer.getConstructor(renderer_meta.type);

                        var _constructor_config = renderer_meta.config || {};
                        _constructor_config._caller = this;

                        var renderer = new _constructor ( _constructor_config );
                        renderer.render();

                        this._content_node.setContent( renderer.get("display_node") );
                    }
                    else {
                        Y.log("manage_window_content_function_action_basic::initializer: No renderer provided", "error");
                    }
                },

                _onLoad: function (e) {
                    Y.log("manage_window_content_function_action_basic::_onLoad");

                    this._parts.center_body = this._content_node;

                    Y.IC.ManageWindowContentFunctionActionBasic.superclass._onLoad.apply(this, arguments);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentFunctionActionBasic = ManageWindowContentFunctionActionBasic;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-function-action-base"
        ]
    }
);
