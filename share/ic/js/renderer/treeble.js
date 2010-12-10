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

// Treeble is really just a data source extension that we'll
// plug handlers into for setting up the actual content of
// the table
YUI.add(
    "ic-renderer-treeble",
    function(Y) {
        var formatters = {
            text: function (elCell, oRecord, oColumn, oData) {
                Y.log("ic-renderer-treeeble formatter::text");
                if (Y.Lang.isObject(oData)) {
                    var text_input = Y.Node.create('<input type="text" name="' + oData.name + '" />');
                    if (Y.Lang.isValue(oData.value)) {
                        text_input.set("value", oData.value);
                    }

                    elCell.setContent(text_input);

                    // TODO: delegation would be better for this
                    text_input.on(
                        "valueChange",
                        function (e) {
                            Y.log("ic-renderer-treeeble formatter::text - valueChange handler - this: " + this);
                            Y.log("ic-renderer-treeeble formatter::text - valueChange handler - oData:  " + Y.dump(oData));
                            oData.value = e.newVal;
                            Y.log("ic-renderer-treeeble formatter::text - valueChange handler - oData:  " + Y.dump(oData));
                        },
                        this
                    );
                }
                else {
                    elCell.setContent("");
                }
            },
            checkbox: function (elCell, oRecord, oColumn, oData) {
                Y.log("ic-renderer-treeeble formatter::checkbox");
                if (Y.Lang.isObject(oData)) {
                    var checkbox = Y.Node.create('<input type="checkbox" name="' + oData.name + '" />');
                    if (Y.Lang.isValue(oData.checked) && oData.checked) {
                        checkbox.set("checked", "checked");
                    }

                    elCell.setContent(checkbox);

                    // TODO: delegation would be better for this
                    checkbox.on(
                        "click",
                        function (e) {
                            Y.log("ic-renderer-treeeble formatter::checkbox - click handler - this: " + this);
                            Y.log("ic-renderer-treeeble formatter::checkbox - click handler - oData:  " + Y.dump(oData));
                            if (oData.checked) {
                                oData.checked = false;
                            }
                            else {
                                oData.checked = true;
                            }
                        },
                        this
                    );
                }
                else {
                    elCell.setContent("");
                }
            }
        };

        var Clazz = Y.namespace("IC").RendererTreeble = Y.Base.create(
            "ic_renderer_treeble",
            Y.IC.RendererBase,
            [],
            {
                _data_source:    null,
                _columns:        null,
                _container_node: null,
                _pg:             null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    var local_columns = [
                        {
                            // taken nearly exactly from example code, basically set up
                            // our initial column that holds the clickable expander
                            formatter: Y.bind(
                                function (elCell, oRecord, oColumn, oData) {
                                    elCell.addClass('treeble-nub');
                                    if (oRecord._children) {
                                        var path  = oRecord._yui_node_path;
                                        var open  = this._data_source.isOpen(path);
                                        var clazz = open ? 'row-open' : 'row-closed';

                                        elCell.addClass('row-toggle');
                                        elCell.replaceClass(/row-(open|closed)/, clazz);
                                        elCell.setContent('<a class="treeble-collapse-nub"></a>');

                                        elCell.on(
                                            'click',
                                            Y.bind(
                                                function (e) {
                                                    this.toggleRow(path);
                                                },
                                                this
                                            )
                                        );
                                    }
                                },
                                this
                            )
                        }
                    ];

                    Y.each(
                        config.headers,
                        function (header, i, a) {
                            Y.log(Clazz.NAME + "::initializer - pre-processing columns");
                            if (Y.Lang.isValue(header.formatter_name)) {
                                header.formatter = Y.bind(
                                    formatters[header.formatter_name],
                                    this
                                );
                                delete header.formatter_name;
                            }
                        },
                        this
                    );

                    config.headers[0].formatter = function (elCell, oRecord, oColumn, oData) {
                        // TODO: minimally make 15 a named constant
                        var padding_left = oRecord._yui_node_depth * 15;
                        elCell.setContent('<span style="padding-left: ' + padding_left + 'px">' + oData + '</span>');
                    };

                    this._columns = [].concat(
                        local_columns,
                        config.headers
                    );

                    config.result_fields.push(
                        {
                            key:    '_children',
                            parser: 'treebledatasource'
                        }
                    );

                    // this gets plugged into both the root data source
                    // and the treeble one, though I don't know why
                    var schema_plugin_config = {
                        fn:  Y.Plugin.DataSourceArraySchema,
                        cfg: {
                            schema: {
                                resultFields: config.result_fields
                            }
                        }
                    };

                    var treeble_config = {
                        generateRequest:        function() {},
                        schemaPluginConfig:     schema_plugin_config,
                        childNodesKey:          '_children',
                        totalRecordsReturnExpr: '.meta.totalRecords'
                    };

                    var data = config.data;
                    var root_data_source = new Y.DataSource.Local (
                        {
                            source: data
                        }
                    );
                    root_data_source.treeble_config = Y.clone(treeble_config, true);
                    root_data_source.plug(schema_plugin_config);

                    this._data_source = new Y.TreebleDataSource (
                        {
                            root:             root_data_source,
                            paginateChildren: false,
                            uniqueIdKey:      '_unique'
                        }
                    );

                    // the paginator is required for handling the request stuff AFAICT
                    // (read: I tried it without and treeble stopped working completely)
                    this._pg = new Y.Paginator (
                        {
                            totalRecords:       1,
                            rowsPerPage:        50,
                            rowsPerPageOptions: [ 1, 2, 5, 10, 25, 50],
                            template:           '{FirstPageLink} {PreviousPageLink} {PageLinks} {NextPageLink} {LastPageLink} <span class="pg-rpp-label">Rows per page:</span> {RowsPerPageDropdown}'
                        }
                    );

                    // TODO: switch this to be an instance method
                    var treeble = this;
                    this._pg.on(
                        "changeRequest",
                        function (state) {
                            Y.log(Clazz.NAME + "::updatePaginator");
                            //Y.log(Clazz.NAME + "::updatePaginator - state: " + Y.dump(state));
                            this.setPage(state.page, true);
                            this.setRowsPerPage(state.rowsPerPage, true);
                            this.setTotalRecords(state.totalRecords, true);

                            treeble.reloadTable();
                        },
                        this._pg
                    );
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._data_source    = null;
                    this._columns        = null;
                    this._container_node = null;
                    this._pg             = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    this._container_node = Y.Node.create("<div></div>");
                    this.get("contentBox").append(this._container_node);

                    // TODO: make this a config switch, most of our uses
                    //       won't require paging
                    //this._pg.render(this.get("contentBox"));

                    this.reloadTable();
                },

                updatePaginator: function (state) {
                    Y.log(Clazz.NAME + "::updatePaginator");
                    //Y.log(Clazz.NAME + "::updatePaginator - state: " + Y.dump(state));
                    this._pg.setPage(state.page, true);
                    this._pg.setRowsPerPage(state.rowsPerPage, true);
                    this._pg.setTotalRecords(state.totalRecords, true);

                    this.reloadTable();
                },

                reloadTable: function () {
                    Y.log(Clazz.NAME + "::reloadTable");
                    var request = {
                        startIndex:  this._pg.getStartIndex(),
                        resultCount: this._pg.getRowsPerPage(),
                        extra: window.treeble_request_extra
                    };
                    Y.log(Clazz.NAME + "::reloadTable - request: " + Y.dump(request));

                    this._data_source.sendRequest(
                        {
                            request: request,
                            callback: {
                                success: Y.bind(
                                    function (e) {
                                        //Y.log("success callback: " + this);
                                        //Y.log("success callback: " + Y.dump(e.response));
                                        this.renderTable(e.response);
                                    },
                                    this
                                ),
                                error: function () {
                                    Y.log("error callback");
                                    alert('error');
                                }
                            }
                        }
                    );
                },

                renderTable: function (response) {
                    Y.log(Clazz.NAME + "::renderTable");

                    var columns = this._columns;

                    var _table_node = Y.Node.create('<table></table>');

                    var _header_row_node = Y.Node.create('<tr></tr>');
                    Y.each(
                        columns,
                        function (column, i, a) {
                            _header_row_node.append('<th>' + (column.label || '&nbsp;') + '</th>');
                        }
                    );
                    _table_node.append(_header_row_node);

                    var hasFormatters = false;

                    var data = response.results;
                    //Y.log(Clazz.NAME + "::renderTable - data: " + Y.dump(data));

                    Y.each(
                        data,
                        function (row, i, a) {
                            var row_node = Y.Node.create('<tr id="' + row._unique + '-' + Y.guid() + '"></tr>');

                            if (i % 2) {
                                row_node.addClass('odd');
                            }
                            if (Y.Lang.isValue(row._add_class)) {
                                Y.log("row _add_class: " + row._add_class);
                                row_node.addClass(row._add_class);
                            }

                            Y.each(
                                columns,
                                function (column, ii, ia) {
                                    var col_node = Y.Node.create('<td></td>');

                                    var value = null;
                                    if (column.formatter) {
                                        hasFormatters = true;
                                    }
                                    else {
                                        value = row[ column.key ];
                                    }

                                    col_node.setContent( Y.Lang.isValue(value) ? value : '&nbsp;' );

                                    row_node.append(col_node);
                                }
                            );

                            _table_node.append(row_node);
                        }
                    );

                    this._container_node.setContent(_table_node);

                    if (hasFormatters) {
                        var rows = this.get("contentBox").one('table').all('tr');

                        var cells;
                        for (var i = 0; i < data.length; i++) {
                            cells = null;
                            for (var j = 0; j < columns.length; j++) {
                                if (columns[j].formatter) {
                                    if (! cells) {
                                        cells = rows.item( i + 1 ).all('td');
                                    }
                                    var key = columns[j].key;

                                    columns[j].formatter(cells.item(j), data[i], columns[j], data[i][ key ]);
                                }
                            }
                        }
                    }

                    //Y.log("setting total records: " + response.meta.totalRecords);
                    this._pg.setTotalRecords(response.meta.totalRecords)
                },

                toggleRow: function (path) {
                    Y.log(Clazz.NAME + "::toggleRow - path: " + path);
                    this._data_source.toggle(path, {}, Y.bind(this.reloadTable, this));
                }
            },
            {
                ATTRS: {
                    data: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-treeble-css",
            "ic-renderer-base",
            "gallery-treeble",
            "event-valuechange"
        ]
    }
);
