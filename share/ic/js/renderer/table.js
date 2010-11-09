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
        var RendererTable;

        RendererTable = function (config) {
            RendererTable.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererTable,
            {
                NAME: "ic_renderer_table",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererTable,
            Y.IC.RendererBase,
            {
                _table: null,

                initializer: function (config) {
                    Y.log("renderer_table::initializer");
                    //Y.log("renderer_table::initializer: " + Y.dump(config));

                    var table_args = {
                        headers: config.headers,
                        rows:    config.rows
                    };
                    if (Y.Lang.isValue(config.caption)) {
                        table_args.caption = config.caption;
                    }

                    this._table = new Y.SimpleDatatable (table_args);
                },

                renderUI: function () {
                    Y.log("renderer_table::renderUI");
                    //Y.log("renderer_table::renderUI - contentBox: " + this.get("contentBox"));

                    this._table.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_table::bindUI");
                },

                syncUI: function () {
                    //Y.log("renderer_table::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererTable = RendererTable;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "gallery-simple-datatable",
            "gallery-simple-datatable-css"
        ]
    }
);
