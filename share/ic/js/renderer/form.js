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
        var RendererForm;

        RendererForm = function (config) {
            RendererForm.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererForm,
            {
                NAME: "ic_renderer_form",
                ATTRS: {
                    caption: {
                        value: ''
                    }
                }
            }
        );

        Y.extend(
            RendererForm,
            Y.IC.RendererBase,
            {
                _form: null,

                initializer: function (config) {
                    Y.log("renderer_form::initializer");
                    //Y.log("renderer_form::initializer - config: " + Y.dump(config));

                    this._form = new Y.IC.Form (config.form_config);
                    Y.log("renderer_form::initializer - _form: " + this._form);
                },

                renderUI: function () {
                    Y.log("renderer_form::renderUI");
                    Y.log("renderer_form::renderUI - contentBox: " + this.get("contentBox"));

                    if (this.get("caption") !== "") {
                        this.get("contentBox").setContent('<span class="ic_renderer_form_caption">' + this.get("caption") + '</span>');
                    }

                    this._form.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_form::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_form::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererForm = RendererForm;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "ic-form"
        ]
    }
);
