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
    "ic-manage-widget-function-list",
    function(Y) {
        var ManageFunctionList;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageFunctionList = function (config) {
            ManageFunctionList.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageFunctionList,
            {
                NAME: "ic_manage_function_list",
                ATTRS: {
                    code: {
                        value: null
                    },
                    kind: {
                        value: null
                    },
                    container: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageFunctionList,
            Y.Widget,
            {
                _meta_data: null,
                _data_source: null,
                _data_table: null,

                initializer: function(config) {
                    Y.log("function initializer: " + this.get("code"));

                    // we can't really use the full capabilities of DataSource.IO and the JSON schema
                    // because we need too much information from the actual request itself to build
                    // our data table dynamically, so fetch our object then just use a local data source
                    // for constructing the table

                    var url = "/manage/function/" + this.get("code") + "/0?_mode=config&_format=json";
                    Y.log("Url: " + url, "debug");

                    var return_data = null;
                    Y.io(
                        url,
                        {
                            sync: true,
                            on: {
                                success: function (txnId, response) {
                                    try {
                                        return_data = Y.JSON.parse(response.responseText);
                                    }
                                    catch (e) {
                                        Y.log("Can't parse JSON: " + e, "error");
                                        return;
                                    }

                                    return;
                                },

                                failure: function (txnId, response) {
                                    Y.log("Failed to get function meta data", "error");
                                }
                            }
                        }
                    );

                    this._meta_data = return_data;
                },

                renderUI: function() {
                    Y.log('list::renderUI');
                    // add a container for the datatable
                    var cb = this.get('contentBox');
                    cb.setContent("");
                    cb.prepend('<div id="' + this.get('code') + '">Loading...</div>');
                    this.set('container', Y.one(this.get('code')));

                    // build the table table from our meta_data
                    var data_table_config = {};
                    this._getDataSource();
                    this._initDataTableFormaters();
                    this._initDataTableSort(data_table_config);
                    this._initDataTablePager(data_table_config);
                    this._adjustDataTableConfig(data_table_config);
                    this._initDataTable(data_table_config);
                    this._data_table.handleDataReturnPayload = this._handleDataReturnPayload;
                },

                bindUI: function() {
                    Y.log('list::bindUI');
                    this._data_table.subscribe("rowMouseoverEvent", this._data_table.onEventHighlightRow);
                    this._data_table.subscribe("rowMouseoutEvent", this._data_table.onEventUnhighlightRow);
                    this._data_table.subscribe("rowClickEvent", this._data_table.onEventSelectRow);
                },

                syncUI: function() {
                    Y.log('list::syncUI');
                },

                _getDataSource: function () {
                    /**
                     *   set up a YUI3 data source that we will then
                     *   wrap in a YUI2 compatibility container to
                     *   pass to the YUI2 data table, presumably when
                     *   YUI3 gets its own datatable we can remove
                     *   this layer
                     **/
                    this._data_source = new Y.DataSource.IO(
                        {
                            source: "/manage/function/" + this.get("code")
                                + "/0?_mode=data&_format=json&_query_mode=listall&"
                        }
                    );
                    this._data_source.plug(
                        {
                            fn: Y.Plugin.DataSourceJSONSchema,
                            cfg: {
                                schema: {
                                    resultListLocator: 'rows',
                                    resultFields: this._meta_data.data_source_fields,
                                    // none but 'total_objects' are actually delivered - modify the server side
                                    metaFields: {
                                        totalRecords: 'total_objects',
                                        paginationRecordOffset : "start_index", 
                                        paginationRowsPerPage : "page_size", 
                                        sortKey: "sort", 
                                        sortDir: "dir" 
                                    }
                                }
                            }
                        }
                    );

                    this._data_source = new Y.DataSourceWrapper(
                        {
                            source: this._data_source
                        }
                    );
                },

                _initDataTableFormaters: function () {
                },

                _initDataTableSort: function (data_table_config) {
                    if (this._meta_data.data_table_initial_sort) {
                        data_table_config.sortedBy = this._meta_data.data_table_initial_sort;
                    }
                },

                _initDataTablePager: function (data_table_config) {
                    if (this._meta_data.paging_provider !== "none") {
                        Y.log("setting up pager: " + this._meta_data.paging_provider);
                        var YAHOO = Y.YUI2;

                        // Define a custom function to route pagination through the Browser History Manager 

                        var pager = new YAHOO.widget.Paginator(
                            {
                                rowsPerPage: this._meta_data.page_count
                            }
                        );

                        data_table_config.paginator = pager;

                        if (this._meta_data.paging_provider === "server") {
                            data_table_config.dynamicData = true;
                            data_table_config.initialRequest = "&startIndex=0";
                        }
                    }
                },

                _adjustDataTableConfig: function (data_table_config) {
                },

                _initDataTable: function (data_table_config) {
                    var YAHOO = Y.YUI2;
                    this._data_table = new YAHOO.widget.DataTable(
                        this.get('code'),
                        this._meta_data.data_table_column_defs,
                        this._data_source,
                        data_table_config
                    );
                },

                _handleDataReturnPayload: function(oRequest, oResponse, oPayload) {
                    oPayload.totalRecords = oResponse.meta.totalRecords;
                    return oPayload;
                },
            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunctionList = ManageFunctionList;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
            "yui2-datatable"
        ]
    }
);
