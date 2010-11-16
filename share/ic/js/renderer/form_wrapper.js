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
    "ic-renderer-form_wrapper",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererFormWrapper = Y.Base.create(
            "ic_renderer_form_wrapper",
            Y.IC.RendererBase,
            [],
            {
                _form: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer - config: " + Y.dump(config));

                    if (! Y.Lang.isValue(config.form_kind)) {
                        config.form_kind = "simple"
                    }

                    this._form = new Y.IC.Form (config.form_config);
                    //Y.log(Clazz.NAME + "::initializer - _form: " + this._form);
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    //Y.log(Clazz.NAME + "::renderUI - contentBox: " + this.get("contentBox"));

                    if (this.get("caption") !== "") {
                        this.get("contentBox").setContent('<span class="ic_renderer_form_caption">' + this.get("caption") + '</span>');
                    }

                    this._form.render(this.get("contentBox"));
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
            "ic-renderer-form_wrapper-css",
            "ic-renderer-base",
            "ic-form"
        ]
    }
);
