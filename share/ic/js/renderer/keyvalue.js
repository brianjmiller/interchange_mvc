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
    "ic-renderer-keyvalue",
    function(Y) {
        var RendererKeyValue;

        RendererKeyValue = function (config) {
            RendererKeyValue.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererKeyValue,
            {
                NAME: "ic_renderer_keyvalue",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererKeyValue,
            Y.IC.RendererBase,
            {
                _title: null,
                _def_list: null,

                initializer: function (config) {
                    Y.log("renderer_keyvalue::initializer");
                    //Y.log("renderer_keyvalue::initializer: " + Y.dump(config));
                    this._title = config.label;

                    this._def_list = Y.Node.create('<dl></dl>');

                    Y.each(
                        config.data,
                        function (v, i, a) {
                            Y.log("adding key/value pair: " + v.label + " => " + v.value);
                            var dt = Y.Node.create('<dt>' + v.label + '</dt>');
                            var dd = Y.Node.create('<dd>' + (v.value !== "" ? v.value : '&nbsp;') + '</dd>');

                            if (v.form) {
                                dd.plug(
                                    Y.IC.Plugin.EditableInPlace,
                                    {
                                        form_config:             v.form,
                                        updated_content_handler: function (response) {
                                            Y.log("updated_content_handler: " + this);
                                            Y.log("updated_content_handler - " + v.label + ": " + Y.dump(response));

                                            // we know by virtue of being an edit in place form
                                            // on a key value pair that we'll get back one key
                                            // (the field name) and one new value which we need
                                            // to stash in our content
                                            var new_value = response.fields[v.code].value;
                                            if (new_value === "") {
                                                new_value = '&nbsp;';
                                            }
                                            this.get("host").setContent(new_value);

                                            // TODO: need to fire an event or something to
                                            //       update the record in the table?
                                        }
                                    }
                                );
                            }

                            this.append(dt);
                            this.append(dd);
                        },
                        this._def_list
                    );
                },

                renderUI: function () {
                    //Y.log("renderer_keyvalue::renderUI");
                    //Y.log("renderer_keyvalue::renderUI - contentBox: " + this.get("contentBox"));
                    this.get("contentBox").append('<span class="key_value_title">' + this._title + '</span><br />');
                    this.get("contentBox").append(this._def_list);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.RendererKeyValue = RendererKeyValue;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-keyvalue-css",
            "ic-renderer-base",
            "ic-plugin-editable-in_place"
        ]
    }
);