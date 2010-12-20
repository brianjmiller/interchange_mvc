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
    "ic-renderer-table",
    function(Y) {
        var _plugin_name_map = {
            ignorable: Y.IC.Plugin.Ignorable
        };

        var Clazz = Y.namespace("IC").RendererTable = Y.Base.create(
            "ic_renderer_table",
            Y.IC.RendererBase,
            [],
            {
                _headers: null,
                _rows:    null,

                _table_node: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._headers = config.headers;
                    this._rows    = config.rows;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._table_node = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._table_node = Y.Node.create('<table></table>');

                    var thead_node = Y.Node.create('<thead></thead>');
                    this._table_node.append(thead_node);

                    var thead_row_node = Y.Node.create('<tr></tr>');
                    thead_node.append(thead_row_node);

                    Y.each(
                        this._headers,
                        function (header, i, a) {
                            var col_node = Y.Node.create('<th>' + header.label + '</th>');
                            if (Y.Lang.isValue(header.attributes)) {
                                //
                                // TODO: .setAttrs wouldn't work for colspan,
                                //       see http://yuilibrary.com/projects/yui3/ticket/2529526
                                //       when it has been fixed this should be able to leverage .setAttrs
                                //
                                //col_node.setAttrs(col.attributes);
                                Y.each(
                                    header.attributes,
                                    function (val, attr, o) {
                                        this.setAttribute(attr, val);
                                    },
                                    col_node
                                );
                            }

                            this.append(col_node);
                        },
                        thead_row_node
                    );

                    var tbody_node = Y.Node.create('<tbody></tbody>');
                    this._table_node.append(tbody_node);

                    Y.each(
                        this._rows,
                        function (row, i, a) {
                            Y.log(Clazz.NAME + "::renderUI - adding row: " + i);
                            Y.log(Clazz.NAME + "::renderUI - row " + i + " config: " + Y.dump(row));
                            var row_node = Y.Node.create('<tr></tr>');

                            if (Y.Lang.isValue(row.add_class)) {
                                Y.log(Clazz.NAME + "::renderUI - row " + i + " add class '" + row.add_class + "'");
                                row_node.addClass(row.add_class);
                            }

                            if (Y.Lang.isValue(row.plugins)) {
                                Y.log(Clazz.NAME + "::renderUI - row " + i + " has plugins");
                                Y.each(
                                    row.plugins,
                                    function (plugin_item) {
                                        var plugin = _plugin_name_map[plugin_item];
                                        Y.log(Clazz.NAME + "::renderUI - row " + i + " plugging " + plugin_item);
                                        row_node.plug(plugin);
                                   }
                                );
                            }

                            if (! Y.Lang.isValue(row.columns)) {
                                row.columns = row;
                            }

                            Y.each(
                                row.columns,
                                function (col, ii, ia) {
                                    Y.log(Clazz.NAME + "::renderUI - row " + i + " adding col " + ii);
                                    Y.log(Clazz.NAME + "::renderUI - row " + i + " col " + ii + " config: " + Y.dump(col));

                                    var col_node = Y.Node.create('<td></td>');
                                    if (Y.Lang.isValue(col.attributes)) {
                                        Y.log(Clazz.NAME + "::renderUI - row " + i + " col " + ii + " attributes: " + Y.dump(col.attributes));
                                        //
                                        // TODO: .setAttrs wouldn't work for colspan,
                                        //       see http://yuilibrary.com/projects/yui3/ticket/2529526
                                        //       when it has been fixed this should be able to leverage .setAttrs
                                        //
                                        //col_node.setAttrs(col.attributes);
                                        Y.each(
                                            col.attributes,
                                            function (val, attr, o) {
                                                this.setAttribute(attr, val);
                                            },
                                            col_node
                                        );
                                    }

                                    if (Y.Lang.isString(col.content)) {
                                        col_node.setContent(col.content);
                                    }
                                    else {
                                        col.content.render = col_node;

                                        Y.IC.Renderer.buildContent( col.content );
                                    }

                                    if (Y.Lang.isValue(col.add_class)) {
                                        Y.log(Clazz.NAME + "::renderUI - row " + i + " add class '" + col.add_class + "'");
                                        col_node.addClass(col.add_class);
                                    }

                                    this.append(col_node);
                                },
                                row_node
                            );

                            this.append(row_node);
                        },
                        tbody_node
                    );

                    this.get("contentBox").setContent(this._table_node);
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
            "ic-renderer-table-css",
            "ic-renderer-base",
            "ic-plugin-ignorable"
        ]
    }
);
