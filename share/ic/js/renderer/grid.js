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
    "ic-renderer-grid",
    function(Y) {
        var RendererGrid;

        RendererGrid = function (config) {
            RendererGrid.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererGrid,
            {
                NAME: "ic_renderer_grid",
                ATTRS: {
                }
            }
        );

        var _percent_to_unit_map = {
            "100": "1",
            "75":  "3-4",
            "66":  "2-3",
            "50":  "1-2",
            "33":  "1-3",
            "25":  "1-4"
        };

        Y.log("Plugin.Ignorable: " + Y.IC.Plugin.Ignorable);
        var _plugin_name_map = {
            ignorable: Y.IC.Plugin.Ignorable
        };

        Y.extend(
            RendererGrid,
            Y.IC.RendererBase,
            {
                _grid_node: null,

                initializer: function (config) {
                    Y.log("renderer_grid::initializer");
                    Y.log("renderer_grid::initializer: " + Y.dump(config));

                    this._grid_node = Y.Node.create('<div class="yui3-g"></div>');

                    Y.each(
                        config,
                        function (row, i, a) {
                            Y.log("adding row: " + i);
                            var row_node      = Y.Node.create('<div class="yui3-u-1"></div>');
                            var row_grid_node = Y.Node.create('<div class="yui3-g"></div>');
                            row_node.append(row_grid_node);

                            if (! Y.Lang.isValue(row.columns)) {
                                row.columns = row;
                            }

                            if (Y.Lang.isValue(row.add_class)) {
                                Y.log('row is class "' + row.add_class + '"');
                                row_node.addClass(row.add_class);
                            }

                            if (Y.Lang.isValue(row.plugins)) {
                                Y.log(RendererGrid.NAME + '::initializer: has plugins');
                                Y.each(
                                    row.plugins,
                                    function (plugin_item, ii, ia) {
                                        var plugin = _plugin_name_map[plugin_item];
                                        Y.log('setting up ' + plugin_item + ": " + plugin);
                                        row_node.plug(plugin);
                                   }
                               );
                            }

                            Y.log('row has ' + row.columns.length + ' column(s)');
                            Y.each(
                                row.columns,
                                function (col, ii, ia) {
                                    Y.log("adding col " + ii + ": " + Y.dump(col));
                                    var unit_class = "yui3-u-";
                                    if (Y.Lang.isValue(col.percent)) {
                                        unit_class += _percent_to_unit_map[col.percent];
                                    }
                                    else {
                                        unit_class += "1";
                                    }

                                    var unit_node = Y.Node.create('<div class="' + unit_class + '"></div>');

                                    // force single content structure into array so that we can
                                    // always handle as an array to allow for multiple content
                                    // items in a single grid unit
                                    var content_items = [];

                                    if (Y.Lang.isValue(col.has_multi_content) && col.has_multi_content) {
                                        content_items = col.content;
                                    }
                                    else {
                                        content_items.push(
                                            {
                                                content_type: col.content_type,
                                                content:      col.content
                                            }
                                        );
                                    }

                                    Y.each(
                                        content_items,
                                        function (config, iii, iia) {
                                            Y.log("content_items loop - " + iii + ": " + Y.dump(config));
                                            var clazz = i + "-" + ii + "-" + iii;
                                            var content_node = Y.Node.create('<div class="' + clazz + '"></div>');

                                            if (config.content_type) {
                                                Y.log("content_type: " + config.content_type);
                                                var content_constructor = Y.IC.Renderer.getConstructor(config.content_type);
                                                config.content._caller = this;

                                                var content = new content_constructor (config.content);
                                                content.render();

                                                Y.log("content display node: " + content.get("boundingBox"));
                                                content_node.setContent(content.get("boundingBox"));
                                            }
                                            else if (Y.Lang.isValue(config.content)) {
                                                content_node.setContent(config.content);
                                            }

                                            //unit_node.append('<br />');
                                            unit_node.append(content_node);
                                        },
                                        this
                                    );

                                    this.append(unit_node);
                                },
                                row_grid_node
                            );

                            this.append(row_node);
                        },
                        this._grid_node
                    );
                },

                renderUI: function () {
                    //Y.log("renderer_grid::renderUI");
                    //Y.log("renderer_grid::renderUI - contentBox: " + this.get("contentBox"));
                    this.get("contentBox").setContent(this._grid_node);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.RendererGrid = RendererGrid;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "ic-plugin-ignorable"
        ]
    }
);
