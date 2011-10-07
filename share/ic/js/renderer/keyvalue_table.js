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
    "ic-renderer-keyvalue_table",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererKeyValueTable = Y.Base.create(
            "ic_renderer_keyvalue_table",
            Y.IC.RendererBase,
            [],
            {
                CONTENT_TEMPLATE: '<table></table>',

                _title: null,
                _data:  null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    this._title = config.label;
                    this._data  = config.data;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._data = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    var cb = this.get("contentBox");

                    var title_row  = Y.Node.create('<tr></tr>');
                    var title_cell = Y.Node.create('<td colspan="2" class="' + this.getClassName("titleCell") + '"></td>');
                    if (Y.Lang.isValue(this._title)) {
                        title_cell.setContent(this._title);
                    }
                    title_row.append(title_cell);
                    cb.append(title_row);

                    Y.each(
                        this._data,
                        function (v, i, a) {
                            Y.log(Clazz.NAME + "::initializer - adding key/value pair: " + v.label + " => " + v.value);
                            var row        = Y.Node.create('<tr></tr>');

                            var label_cell = Y.Node.create('<td>' + v.label + '</td>');
                            label_cell.addClass( this.getClassName("labelCell") );

                            var value_cell = Y.Node.create('<td>' + v.value + '</td>');
                            value_cell.addClass( this.getClassName("valueCell") );

                            row.append(label_cell);
                            row.append(value_cell);
                            cb.append(row);

                            if (v.form) {
                                value_cell.plug(
                                    Y.IC.Plugin.EditableInPlace,
                                    {
                                        form_config:             v.form,
                                        updated_content_handler: function (response) {
                                            Y.log(Clazz.NAME + "::initializer - updated_content_handler: " + this);
                                            //Y.log(Clazz.NAME + "::initializer - updated_content_handler - " + v.label + ": " + Y.dump(response));

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
                        },
                        this
                    );
                }
            },
            {
                ATTRS: {}
            }
        );

        Y.IC.Renderer.registerConstructor("KeyValueTable", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-keyvalue_table-css",
            "ic-renderer-base",
            "ic-plugin-editable-in_place"
        ]
    }
);
