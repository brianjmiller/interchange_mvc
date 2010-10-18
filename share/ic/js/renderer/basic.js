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
    "ic-renderer-basic",
    function(Y) {
        var RendererBasic;

        RendererBasic = function (config) {
            RendererBasic.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererBasic,
            {
                NAME: "ic_renderer_basic",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererBasic,
            Y.IC.RendererBase,
            {
                _title: null,
                _body:  null,

                initializer: function (config) {
                    //Y.log("renderer_basic::initializer");
                    //Y.log("renderer_basic::initializer: " + Y.dump(config));
                    this._title = config.label;
                    this._body  = config.data;
                },

                renderUI: function () {
                    //Y.log("renderer_basic::renderUI");
                    //Y.log("renderer_basic::renderUI - contentBox: " + this.get("contentBox"));
                    if (Y.Lang.isValue(this._title)) {
                        this.get("contentBox").append('<span class="title">' + this._title + '</span><br />');
                    }
                    this.get("contentBox").append(this._body);
                },

                bindUI: function () {
                    //Y.log("renderer_basic::bindUI");
                },

                syncUI: function () {
                    //Y.log("renderer_basic::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererBasic = RendererBasic;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base"
        ]
    }
);
