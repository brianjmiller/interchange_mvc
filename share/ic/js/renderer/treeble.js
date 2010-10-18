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
        var RendererTreeble;

        RendererTreeble = function (config) {
            RendererTreeble.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererTreeble,
            {
                NAME: "ic_renderer_treeble",
                ATTRS: {
                    data: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            RendererTreeble,
            Y.IC.RendererBase,
            {
                _data_source:    null,
                _columns:        null,
                _container_node: null,
                _pg:             null,

                initializer: function (config) {
                    Y.log("renderer_treeble::initializer");
                    //Y.log("renderer_treeble::initializer: " + Y.dump(config));

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
                        'changeRequest',
                        function (state) {
                            Y.log("renderer_treeble::updatePaginator");
                            Y.log("renderer_treeble::updatePaginator - state: " + Y.dump(state));
                            this.setPage(state.page, true);
                            this.setRowsPerPage(state.rowsPerPage, true);
                            this.setTotalRecords(state.totalRecords, true);

                            treeble.reloadTable();
                        },
                        this._pg
                    );
                },

                renderUI: function () {
                    Y.log("renderer_treeble::renderUI");

                    this._container_node = Y.Node.create("<div></div>");
                    this.get("contentBox").append(this._container_node);

                    // TODO: make this a config switch, most of our uses
                    //       won't require paging
                    //this._pg.render(this.get("contentBox"));

                    this.reloadTable();
                },

                bindUI: function () {
                    Y.log("renderer_treeble::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_treeble::syncUI");
                },

                updatePaginator: function (state) {
                    Y.log("renderer_treeble::updatePaginator");
                    //Y.log("renderer_treeble::updatePaginator - state: " + Y.dump(state));
                    this._pg.setPage(state.page, true);
                    this._pg.setRowsPerPage(state.rowsPerPage, true);
                    this._pg.setTotalRecords(state.totalRecords, true);

                    this.reloadTable();
                },

                reloadTable: function () {
                    Y.log("renderer_treeble::reloadTable");
                    var request = {
                        startIndex:  this._pg.getStartIndex(),
                        resultCount: this._pg.getRowsPerPage(),
                        extra: window.treeble_request_extra
                    };
                    Y.log("renderer_treeble::reloadTable - request: " + Y.dump(request));

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
                    Y.log("renderer_treeble::renderTable");

                    var columns = this._columns;

                    var _table_node = Y.Node.create('<table></table>');
                    // NEXT - add a display panel and handle this click, etc.
                    Y.delegate(
                        "click",
                        function (e) {
                            Y.log("table row click");
        //  The list item that matched the provided selector is the 
        //  default 'this' object
        Y.log("Default scope: " + this.get("id"));
 
        //  The list item that matched the provided selector is 
        //  also available via the event's currentTarget property
        //  in case the 'this' object is overridden in the subscription.
        Y.log("Clicked list item: " + e.currentTarget.get("id"));
 
        //  The actual click target, which could be the matched item or a
        //  descendant of it.
        Y.log("Event target: " + e.target); 
 
        //  The delegation container is added to the event facade
        Y.log("Delegation container: " + e.container.get("id"));  
                        },
                        _table_node,
                        "tr"
                    );

                    var s = '';

                    s += '<tr>';
                    for (var i = 0; i < columns.length; i++) {
                        s += '<th>';
                        s += columns[i].label || '&nbsp;';
                        s += '</th>';
                    }
                    s += '</tr>';

                    var hasFormatters = false;

                    var data = response.results;
                    //Y.log("renderer_treeble::renderTable - data: " + Y.dump(data));
                    for (var i = 0; i < data.length; i++) {
                        s += '<tr';
                        if (i % 2) {
                            s += ' class="odd"';
                        }
                        s += '>';

                        for (var j = 0; j < columns.length; j++) {
                            s += '<td>';

                            var key   = columns[j].key;
                            var value = null;
                            if (columns[j].formatter) {
                                hasFormatters = true;
                            }
                            else {
                                value = data[i][ key ];
                            }
                            s += ! Y.Lang.isUndefined(value) && value !== null ? value : '&nbsp;';
                            s += '</td>';
                        }
                        s += '</tr>';
                    }

                    _table_node.setContent(s);

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
                    Y.log("renderer_treeble::toggleRow - path: " + path);
                    this._data_source.toggle(path, {}, Y.bind(this.reloadTable, this));
                }
            }
        );

        Y.namespace("IC");
        Y.IC.RendererTreeble = RendererTreeble;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "gallery-treeble"
        ]
    }
);
