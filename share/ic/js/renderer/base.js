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
    "ic-renderer-base",
    function(Y) {
        var RendererBase;

        RendererBase = function (config) {
            RendererBase.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererBase,
            {
                NAME: "ic_renderer_base",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererBase,
            Y.Widget,
            {
                _caller:            null,
                _meta:              null,

                initializer: function (config) {
                    Y.log("renderer_base::initializer");
                    //Y.log("renderer_base::initializer: " + Y.dump(config));
                    this._caller = config._caller;
                },

                renderUI: function () {
                    Y.log("renderer_base::renderUI");
                    Y.log("renderer_base::renderUI - contentBox: " + this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_base::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_base::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererBase = RendererBase;
    },
    "@VERSION@",
    {
        requires: [
            "widget"
        ]
    }
);
