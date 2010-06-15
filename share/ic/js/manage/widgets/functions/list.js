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

        ManageFunctionList = function (config) {
            ManageFunctionList.superclass.constructor.apply(this, arguments);
            this.publish('manageFunctionList:tablerendered', {
                broadcast:  2,   // global notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        ManageFunctionList.NAME = "ic_manage_function_list";

        Y.extend(
            ManageFunctionList,
            Y.IC.ManageFunction,
            {
                _data_source: null,
                _data_table: null,

                _buildUI: function() {
                    // build the table table from our meta_data
                    var data_table_config = {};
                    this._getDataSource();
                    this._initDataTableFormaters();
                    this._initDataTableSort(data_table_config);
                    this._initDataTablePager(data_table_config);
                    this._adjustDataTableConfig(data_table_config);
                    this._initDataTable(data_table_config);
                    this._data_table.handleDataReturnPayload = this._handleDataReturnPayload;
                    this._bindDataTableEvents()
                    this.fire('manageFunction:loaded');
                },

                _bindDataTableEvents: function() {
                    this._data_table.subscribe("rowMouseoverEvent", this._data_table.onEventHighlightRow);
                    this._data_table.subscribe("rowMouseoutEvent", this._data_table.onEventUnhighlightRow);
                    this._data_table.subscribe("rowClickEvent", this._data_table.onEventSelectRow);
                    this._data_table.subscribe("postRenderEvent", Y.bind(this.onPostRenderEvent, this));
                },

                onPostRenderEvent: function (e) {
                    Y.log('list::onPostRenderEvent');
                    this.fire('manageFunctionList:tablerendered');
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
                        // Y.log("setting up pager: " + this._meta_data.paging_provider);
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
                        this.get('code'), // renders us into this._content_node
                        this._meta_data.data_table_column_defs,
                        this._data_source,
                        data_table_config
                    );
                },

                _handleDataReturnPayload: function(oRequest, oResponse, oPayload) {
                    oPayload.totalRecords = oResponse.meta.totalRecords;
                    return oPayload;
                },

                getHeaderText: function () {
                    if (this._meta_data) {
                        Y.log(this._meta_data);
                        var header = ' List ' + this._meta_data.model_name_plural;
                        Y.log('list::getHeaderText - header: ' + header);
                        return header;
                    }
                    else {
                        Y.log('list::getHeaderText - header is null - no meta_data');
                        return null;
                    }
                }

            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunctionList = ManageFunctionList;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-function",
            "yui2-datatable"
        ]
    }
);
