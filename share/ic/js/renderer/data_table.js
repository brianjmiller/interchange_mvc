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
        var Clazz = Y.namespace("IC").RendererDataTable = Y.Base.create(
            "ic_renderer_data_table",
            Y.IC.RendererBase,
            [],
            {
                _table: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._table = new Y.SimpleDatatable (config.table_config);
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._table = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._table.render(this.get("contentBox"));
                }
            }
        );
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
