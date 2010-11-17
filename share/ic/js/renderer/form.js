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
    "ic-renderer-form",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererForm = Y.Base.create(
            "ic_renderer_form",
            Y.IC.RendererBase,
            [],
            {
                _form_node:      null,

                _action:         null,
                _content_config: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._action         = config.action;
                    this._content_config = config.content;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._form_node      = null;
                    this._action         = null;
                    this._content_config = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Y.log(Clazz.NAME + "::renderUI - _content_config: " + Y.dump(this._content_config));

                    // TODO: replace with call to I/O
                    this._form_node = Y.Node.create('<form action="' + this._action + '"></form>');

                    var content_node = Y.IC.Renderer.buildContent(this._content_config, this);
                    this._form_node.setContent(content_node);

                    this.get("contentBox").setContent(this._form_node);
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    // TODO: need to bind to submit buttons
                }
            },
            {
                ATTRS: {}
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-form-css",
            "ic-renderer-base"
        ]
    }
);
