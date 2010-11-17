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
        var Clazz = Y.namespace("IC").RendererBasic = Y.Base.create(
            "ic_renderer_basic",
            Y.IC.RendererBase,
            [],
            {
                _title: null,
                _body:  null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    this._title = config.label;
                    this._body  = config.data;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");
                    this._title = null;
                    this._body  = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    if (Y.Lang.isValue(this._title)) {
                        this.get("contentBox").append('<span class="title">' + this._title + '</span><br />');
                    }
                    this.get("contentBox").append(this._body);
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
            "ic-renderer-basic-css",
            "ic-renderer-base"
        ]
    }
);
