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
    "ic-renderer-data_table",
    function(Y) {
        var RendererDataTable;

        RendererDataTable = function (config) {
            RendererDataTable.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererDataTable,
            {
                NAME: "ic_renderer_data_table",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererDataTable,
            Y.IC.RendererBase,
            {
                _table: null,

                initializer: function (config) {
                    Y.log("renderer_data_table::initializer");
                    //Y.log("renderer_data_table::initializer: " + Y.dump(config));

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
                    Y.log("renderer_data_table::renderUI");
                    //Y.log("renderer_data_table::renderUI - contentBox: " + this.get("contentBox"));

                    this._table.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_data_table::bindUI");
                },

                syncUI: function () {
                    //Y.log("renderer_data_table::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererDataTable = RendererDataTable;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-data_table-css",
            "ic-renderer-base",
            "gallery-simple-datatable",
            "gallery-simple-datatable-css"
        ]
    }
);
