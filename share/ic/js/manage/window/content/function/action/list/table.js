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
    "ic-manage-window-content-function-action-list-table",
    function(Y) {
        var ManageWindowContentFunctionActionListTable;

        ManageWindowContentFunctionActionListTable = function (config) {
            ManageWindowContentFunctionActionListTable.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunctionActionListTable,
            {
                NAME: "ic_manage_content_function_action_list_table",
                ATTRS: {
                    // TODO: break this out into separate properties
                    meta: {
                        value: null
                    },
                    addtl_args: {
                        value: null
                    },

                    // the number of rows we feel will fit
                    max_rows: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentFunctionActionListTable,
            Y.Base,
            {
                _caller:          null,
                _data_source:     null,
                _data_table:      null,
                _data_pager:      null,
                _has_data:        false,
                _prev_req:        "",
                _already_sending: false,

                initializer: function (config) {
                    Y.log("manage_window_content_function_action_list_table::initializer");
                    //Y.log("manage_window_content_function_action_list_table::initializer: " + Y.dump(config));
                    this._caller = config._caller;

                    this._initMaxRows();

                    this._initDataSource();

                    var data_table_config = this._initDataTableConfig();

                    this._initDataTableFormatters();
                    this._initDataTableSort(data_table_config);

                    if (this.get("meta").paging_provider !== "none") {
                        this._initDataTablePager(data_table_config);
                    }

                    this._initDataTable(config.render_to, data_table_config);

                    this._data_table.handleDataReturnPayload = Y.bind(
                        this._handleDataReturnPayload, this
                    );

                    this._bindEvents();
                },

                _initDataSource: function () {
                    Y.log("manage_window_content_function_action_list_table::_initDataSource");
                   
                    //
                    // set up a YUI3 data source that we will then wrap in a YUI2 
                    // compatibility container to pass to the YUI2 data table, 
                    // presumably when YUI3 gets its own datatable we can remove
                    // this layer 
                    //

                    var source = this._caller.getBaseURL() + "/data?_format=json";
                    Y.log("manage_window_content_function_action_list_table::_initDataSource - source: " + source);

                    var source_fields = this.get("meta").data_source_fields;

                    var row_actions   = this.get("meta").row_actions;
                    if (row_actions) {
                        source_fields.push(
                            {
                                key:    "_options",

                                // TODO: we could make this handle per row options, for example adding
                                //       a "review" link to orders pending review, etc.
                                parser: Y.bind(
                                    function (data) {
                                        var return_data = "";

                                        Y.each(
                                            this.get("meta").row_actions,
                                            function (v, i, a) {
                                                if (return_data !== "") return_data += " | ";
                                                return_data += '<a id="' + v.code + '-' + Y.guid() + '" class="row_action_link">' + v.label + '</a>';
                                            }
                                        );

                                        return return_data;
                                    },
                                    this
                                )
                            }
                        );
                    }

                    // whether we're dealing with an unfiltered list or
                    // a search is determined by the presence of addtl_args
                    // TODO: need to improve our handling here
                    var addtl_args = this.get("addtl_args");
                    if (addtl_args) {
                        source += "&filter_mode=search&" + addtl_args;
                    }

                    this._data_source = new Y.DataSource.IO (
                        {
                            source: source
                        }
                    );
                    this._data_source.plug(
                        {
                            fn:  Y.Plugin.DataSourceJSONSchema,
                            cfg: {
                                schema: {
                                    resultListLocator: "rows",
                                    resultFields:      source_fields,
                                    metaFields:        {
                                        totalRecords:           "total_objects",
                                        paginationRecordOffset: "startIndex",
                                        paginationRowsPerPage:  "results",
                                        sortKey:                "sort", 
                                        sortDir:                "dir"
                                    }
                                }
                            }
                        }
                    );
                        
                    // Wrapper to allow YUI2 DT to talk to YUI3 DS
                    this._wrapped_data_source = new Y.DataSourceWrapper (
                        {
                            source: this._data_source
                        }
                    );
                },

                _initDataTableConfig: function () {
                    Y.log("manage_window_content_function_action_list_table::_initDataTableConfig");
                    var config = {
                        draggableColumns: true
                        //initialLoad: false
                    };

                    if (this.get("meta").paging_provider === "server") {
                        Y.log("manage_window_content_function_action_list_table::_initDataTableConfig - setting dynamic data to true");
                        config.dynamicData     = true;
                        config.initialRequest  = "&startIndex=0&results=" + this.get("max_rows");
                        config.generateRequest = Y.bind( this.dynamicDataGenerateRequest, this );
                    }

                    return config;
                },

                _initDataTableFormatters: function () {
                },

                _initDataTableSort: function (data_table_config) {
                    Y.log("manage_window_content_function_action_list_table::_initDataTableSort");

                    if (Y.Lang.isValue(this.get("meta").data_table_initial_sort)) {
                        // make a copy, as config may change the values
                        data_table_config.sortedBy = Y.merge(
                            this.get("meta").data_table_initial_sort
                        );
                    }
                },

                _initDataTablePager: function (data_table_config) {
                    Y.log("manage_window_content_function_action_list_table::_initDataTablePager");
                    Y.log("manage_window_content_function_action_list_table::_initDataTablePager - setting up pager: " + this.get("meta").paging_provider);

                    this._data_pager = new Y.YUI2.widget.Paginator (
                        {
                            alwaysVisible: false,
                            rowsPerPage:   this.get("max_rows")
                        }
                    );

                    data_table_config.paginator = this._data_pager;
                },

                _initDataTable: function (render_to, data_table_config) {
                    Y.log("manage_window_content_function_action_list_table::_initDataTable");

                    var column_defs = this.get("meta").data_table_column_defs;

                    var row_actions = this.get("meta").row_actions;
                    if (row_actions) {
                        column_defs.push(
                            {
                                key:       "_options",
                                label:     "Options",
                                sortable:  false,
                                resizable: false
                            }
                        );
                    }

                    this._data_table = new Y.YUI2.widget.ScrollingDataTable(
                        render_to,
                        column_defs,
                        this._wrapped_data_source,
                        data_table_config
                    );
                },

                _initMaxRows: function (container) {
                    Y.log("manage_window_content_function_action_list_table::_initMaxRows");

                    if (! container) {
                        // using the layout from the function we can look at its units
                        // to determine a height

                        // TODO: we clearly need a better way to determine this
                        //       if for no other reason than we may be in the top
                        //       of the h_divided layout
                        container = this._caller._caller._containing_pane._layouts.full._layout.getUnitByPosition("center");
                    }

                    var unit_height = container.get("height");
                    var magic       = 58; // table header (24) + 1 paginator (34) height
                    magic += 21;
                    var total_recs  = this.get("meta").total_objects;
                    var row_height  = 24;

                    // how many rows will fit in my unit?
                    var num_rows = Math.floor(
                        (unit_height - magic) / row_height
                    );
                    //Y.log("manage_window_content_function_action_list_table::getMaxNumRows - calculatd rows: " + num_rows);

                    this.set("max_rows", Math.min(num_rows, total_recs));

                    return;
                },

                _handleDataReturnPayload: function (oRequest, oResponse, oPayload) {
                    Y.log("manage_window_content_function_action_list_table::_handleDataReturnPayload");

                    oPayload.totalRecords = oResponse.meta.totalRecords;

                    return oPayload;
                },

                _bindEvents: function () {
                    Y.log("manage_window_content_function_action_list_table::_bindEvents");
                    this.on(
                        "updateData",
                        Y.bind(this._onUpdateData, this)
                    );

                    this._data_table.subscribe(
                        "rowMouseoverEvent", 
                        this._data_table.onEventHighlightRow
                    );
                    this._data_table.subscribe(
                        "rowMouseoutEvent", 
                        this._data_table.onEventUnhighlightRow
                    );
                    this._data_table.subscribe(
                        "rowClickEvent", 
                        this._data_table.onEventSelectRow
                    );
                    this._data_table.subscribe(
                        "rowSelectEvent", 
                        Y.bind(this._onRowSelectEvent, this)
                    );
                    if (this.get("meta").row_actions) {
                        //Y.log("manage_window_content_function_action_list_table::_bindEvents - installing row action click handler");
                        Y.delegate(
                            "click",
                            this._onRowActionClick,
                            this._data_table.getContainerEl(),
                            "a.row_action_link",
                            this
                        );
                    }
                },

                _onUpdateData: function (e) {
                    Y.log("manage_window_content_function_action_list_table::_onUpdateData");

                    var req = null
                    if (this.get("meta").paging_provider === "server") {
                        req = this.dynamicDataGenerateRequest(this._data_table.getState(), this._data_table);

                        // TODO: need to set state properties, minimally the start index

                        this._wrapped_data_source.sendRequest(
                            req,
                            {
                                //success: this._data_table.onDataReturnInitializeTable
                                success:  this._data_table.onDataReturnSetRows,
                                failure:  this._data_table.onDataReturnSetRows,
                                argument: this._data_table.getState(),
                                scope:    this._data_table
                            }
                        );
                    }
                    else {
                        this._data_table.render();
                    }
                },

                _onRowSelectEvent: function (e) {
                    Y.log("manage_window_content_function_action_list_table::_onRowSelectEvent");
                },

                _onRowActionClick: function (e) {
                    Y.log("manage_window_content_function_action_list_table::_onRowActionClick");
                    //Y.log("manage_window_content_function_action_list_table::_onRowActionClick - e.target: " + e.target);
                    var matches         = e.target.get("id").match("^([^-]+)-(?:.+)$");
                    var selected_action = matches[1];

                    this._caller.setCurrentRecordWithAction(
                        this._data_table.getRecord( this._data_table.getLastSelectedRecord() ),
                        selected_action
                    );
                },

                updateAddtlArgs: function (addtl_args) {
                    Y.log("manage_window_content_function_action_list_table::updateAddtlArgs");
                },

                // this is a wrapper method to make afterHostMethod used by plugins happy
                // it just passes through to what we'd like to call directly
                dynamicDataGenerateRequest: function (oState, oSelf) {
                    Y.log("manage_window_content_function_action_list_table::dynamicDataGenerateRequest");
                    return this._dynamicDataGenerateRequest(oState, oSelf);
                },

                // this method is only used when paging_provider is set to server so that we can
                // do various things before/after the request generation by plugins, etc. and 
                // it is installed as a bounded function in the data table itself
                _dynamicDataGenerateRequest: function (oState, oSelf) {
                    Y.log("manage_window_content_function_action_list_table::_dynamicDataGenerateRequest");
                    Y.log("manage_window_content_function_action_list_table::_dynamicDataGenerateRequest - oState: " + Y.dump(oState));
                    Y.log("manage_window_content_function_action_list_table::_dynamicDataGenerateRequest - oSelf: " + oSelf);

                    var sort, dir, startIndex, results;

                    oState = oState || { pagination: null, sortedBy: null };

                    sort = (oState.sortedBy) ? oState.sortedBy.key : oSelf.getColumnSet().keys[0].getKey();
                    dir  = (oState.sortedBy && oState.sortedBy.dir === oSelf.CLASS_DESC) ? "desc" : "asc";

                    startIndex = (oState.pagination) ? oState.pagination.recordOffset : 0;
                    results    = (oState.pagination) ? oState.pagination.rowsPerPage : null;

                    var result = "&results=" + results + "&startIndex="  + startIndex + "&sort=" + sort + "&dir=" + dir;
                    Y.log("manage_window_content_function_action_list_table::_dynamicDataGenerateRequest - result: " + result);

                    this._tmp_dynamic_data_request = result;

                    return result;
                }
            }
        );
        
        Y.namespace("IC");
        Y.IC.ManageWindowContentFunctionActionListTable = ManageWindowContentFunctionActionListTable;
    },
    "@VERSION@",
    {
        requires: [
            "base",
            "datasource",
            "pluginhost",
            "gallery-datasource-wrapper",
            "yui2-paginator",
            "yui2-datatable",
            "yui2-datasource",
            "querystring"
        ]
    }
);
