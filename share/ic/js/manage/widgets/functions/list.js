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
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        ManageFunctionList.NAME = "ic_manage_function_list";

        Y.extend(
            ManageFunctionList,
            Y.IC.ManageFunction,
            {
                STATE_PROPERTIES: {
                    'srec': 1,         // selected record
                    'results': 1,      // results
                    'startIndex': 1,  // start index
                    'sort': 1,         // sort column
                    'dir' : 1          // sort direction
                },

                _data_source: null,
                _data_table: null,
                _data_pager: null,
                _has_data: false,

                _buildUI: function() {
                    // Y.log('list::_buildUI');
                    // build the table from our meta_data
                    var data_table_config = {};
                    this._getDataSource();
                    this._initDataTableFormaters();
                    this._initDataTableSort(data_table_config);
                    this._initDataTablePager(data_table_config);
                    this._adjustDataTableConfig(data_table_config);
                    this._initDataTable(data_table_config);
                    this._data_table.handleDataReturnPayload = Y.bind(
                        this._handleDataReturnPayload, this
                    );
                    this._bindDataTableEvents();
                    this.after('stateChange', Y.bind(this._afterStateChange, this));
                    if (!this._on_history_change) {
                        this._on_history_change = Y.on(
                            'history-lite:change', 
                            Y.bind(this._onHistoryChange, this)
                        );
                    }
                    this._setInitialState();
                    this.fire('manageFunction:loaded');
                },

                _setInitialState: function() {
                    // Y.log('list:_setInitialState');
                    var rh = this.getRelaventHistory();
                    if (Y.Object.size(rh) === 0) {
                        rh = this._generateRequest();
                        rh.srec = '-1';
                    }
                    this.set('state', rh);
                },

                _bindDataTableEvents: function() {
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
                        "postRenderEvent", 
                        Y.bind(this.onPostRenderEvent, this)
                    );
                    this._data_table.subscribe(
                        "rowSelectEvent", 
                        Y.bind(this.onRowSelectEvent, this)
                    );

                    // the state/history management additions:
                    this._data_table.doBeforeLoadData = Y.bind(
                        this._doBeforeLoadData, 
                        this
                    );
                    this._data_pager.unsubscribe(
                        "changeRequest", 
                        this._data_table.onPaginatorChangeRequest
                    ); 
                    this._data_pager.subscribe(
                        "changeRequest", 
                        this._handlePagination, 
                        this, 
                        true
                    );

                    this._data_table.sortColumn = Y.bind(this._handleSorting, this);
                },

                hide: function () {
                    // Y.log('list::hide - setting srec to -1');
                    this.set('state.srec', -1);
                    ManageFunctionList.superclass.hide.apply(this, arguments);
                },

                getHeaderText: function () {
                    if (this._meta_data) {
                        // Y.log(this._meta_data);
                        var header = ' List ' + this._meta_data.model_name_plural;
                        // Y.log('list::getHeaderText - header: ' + header);
                        return header;
                    }
                    else {
                        // Y.log('list::getHeaderText - header is null - no meta_data');
                        return null;
                    }
                },

                onPostRenderEvent: function (e) {
                    // Y.log('list::onPostRenderEvent');
                    this.fire('manageFunctionList:tablerendered');
                },

                onRowSelectEvent: function (e) {
                    // Y.log('list::onRowSelectEvent');

                    /*
                     *  get the primary key for this table.
                     *  this is not currently in the meta_data, 
                     *  so i make the assumption that it's the first column
                     */
                    var pk = this._meta_data.data_source_fields[0].key;
                    // encode the pk value - it will end up in the browser history
                    var pkv = encodeURIComponent(e.record._oData[pk]);
                    if (this.get('state.srec') !== pkv) {
                        this.set('state.srec', pkv);
                        this._notifyHistory();
                    }
                },

                selectRecordFromHistory: function () {
                    // Y.log('list::selectRecordFromHistory srec');

                    /* 
                     *  preselect a record specified in the browser history
                     *  this only works if the record is on the first page.
                     *  need to integrate the paginator with the history manager...
                     */  

                    var srec = this.get('state.srec');
                    // Y.log(srec);
                    if (srec) {
	                    var recs = this._data_table.getRecordSet()._records;
                        var pk = this._meta_data.data_source_fields[0].key;
                        /*
                        Y.log('pk -> recs');
                        Y.log(pk);
                        Y.log(recs);
                        */
	                    var i,len;
	                    for (i = 0,len = recs.length; i < len; ++i) { 
	                        if (recs[i] && 
                                (recs[i].getData(pk) === decodeURIComponent(srec))) { 
	                            this._data_table.selectRow(recs[i]); 
	                            break; 
	                        } 
                        }
	                }
                },

                setNewPaginator: function (num_results, offset) {
                    if (!num_results) num_results = this._meta_data.page_count;
                    if (!offset) offset = 0;
                    // Y.log('list::setNewPaginator - num_results:' + 
                    //       num_results + ' offset:' + offset);
                    this._has_data = false;
                    var YAHOO = Y.YUI2;
                    var new_state = this._data_pager.getState({
                        rowsPerPage: num_results,
                        recordOffset: offset
                    });
                    this._data_pager = new YAHOO.widget.Paginator(new_state);
                    this._data_table.set('paginator', this._data_pager);

                    var state = this.get('state');
                    state.results = num_results;
                    state.startIndex = offset;
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
                                    // none but 'total_objects' are actually delivered
                                    //  modify the server side
                                    metaFields: {
                                        totalRecords: 'total_objects',
                                        paginationRecordOffset : "startIndex", 
                                        paginationRowsPerPage : "results",
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
                    // Y.log('list::_initDataTableSort');
                    if (Y.Lang.isValue(this._meta_data.data_table_initial_sort)) {
                        // make a copy, as config may change the values
                        data_table_config.sortedBy = Y.merge(
                            this._meta_data.data_table_initial_sort
                        );
                    }
                },

                _initDataTablePager: function (data_table_config) {
                    if (this._meta_data.paging_provider !== "none") {
                        // Y.log("setting up pager: " + this._meta_data.paging_provider);
                        var YAHOO = Y.YUI2;
                        this._data_pager = new YAHOO.widget.Paginator(
                            {
                                rowsPerPage: this._meta_data.page_count
                            }
                        );
                        data_table_config.paginator = this._data_pager;
                        if (this._meta_data.paging_provider === "server") {
                            data_table_config.dynamicData = true;
                            data_table_config.initialRequest = "&startIndex=0";
                        }
                    }
                },

                _adjustDataTableConfig: function (data_table_config) {
                    data_table_config.initialLoad = false;
                },

                _initDataTable: function (data_table_config) {
                    var YAHOO = Y.YUI2;
                    this._data_table = new YAHOO.widget.DataTable(
                        this.get('code'), // renders us into this._content_node
                        this._meta_data.data_table_column_defs,
                        this._data_source,
                        data_table_config
                    );
                    this._data_table.showTableMessage(
                        this._data_table.get("MSG_LOADING"), 
                        YAHOO.widget.DataTable.CLASS_LOADING
                    );
                },

                _handleDataReturnPayload: function(oRequest, oResponse, oPayload) {
                    oPayload.totalRecords = oResponse.meta.totalRecords;
                    return oPayload;
                },

                _doBeforeLoadData: function(oRequest, oResponse, oPayload) { 
                    // Y.log('list::doBeforeLoadData');
                    var meta = oResponse.meta; 

                    oPayload.totalRecords = meta.totalRecords || oPayload.totalRecords; 
                    oPayload.pagination = { 
                        rowsPerPage: Number(meta.paginationRowsPerPage) || 
                            this._meta_data.page_count,
                        recordOffset: Number(meta.paginationRecordOffset) || 0 
                    }; 

                    // Convert from server value to DataTable format
                    if (meta.sortDir) {
                        if (!meta.sortDir.match(/^yui\-dt\-/)) {
                            meta.sortDir = 'yui-dt-' + meta.sortDir;
                        }
                    }
                    else {
                        if (this._meta_data.data_table_initial_sort &&
                            this._meta_data.data_table_initial_sort.dir) {
                            meta.sortDir = 'yui-dt-' + 
                                this._meta_data.data_table_initial_sort.dir;
                        }
                        else {
                            meta.sortDir = 'yui-dt-desc'
                        }
                    }
                    oPayload.sortedBy = {
                        key: meta.sortKey || 
                            this._meta_data.data_table_initial_sort.key || 
                            "id",
                        dir: meta.sortDir
                    }; 

                    this._has_data = true;
                    var new_state = {
                        startIndex: oPayload.pagination.recordOffset,
                        results: oPayload.pagination.rowsPerPage,
                        sort: oPayload.sortedBy.key,
                        dir: oPayload.sortedBy.dir,
                        srec: this.get('state.srec') || '-1'
                    };
                    this.set('state', new_state);
                    return true; 
                },

                _handlePagination: function (state) { 
                    // Y.log('list::_handlePagination - state');

                    // The next state will reflect the new pagination values 
                    // while preserving existing sort values 
                    var sorted_by = this._data_table.get("sortedBy") || 
                        {key: null, dir: null};
                    var new_state = this._generateRequest( 
                        state.recordOffset, 
                        sorted_by.key, 
                        sorted_by.dir, 
                        state.rowsPerPage 
                    );
                    var srec = this.get('state.srec');
                    if (srec) new_state.srec = srec;
                    this.set('state', new_state);
                    // Y.log(this.get('state'));
                },

                _handleSorting: function (col, dir) {
                    // Y.log('list::_handleSorting - col');
                    // Y.log(col);

                    // Calculate next sort direction for given Column
                    var sort_dir = this._data_table.getColumnSortDir(col);

                    // The next state will reflect the new sort values
                    // while preserving existing pagination rows-per-page
                    // As a best practice, a new sort will reset to page 0
                    var new_state = this._generateRequest(
                        0, 
                        col.key, 
                        sort_dir, 
                        this._data_table.get("paginator").getRowsPerPage()
                    );
                    var srec = this.get('state.srec');
                    if (srec) new_state.srec = srec;
                    this.set('state', new_state);
                },

                _generateRequest: function (start_index, sort_key, dir, results) { 
                    // Y.log('list::_generateRequest');
                    var meta_sort_key = 'id';
                    var meta_sort_dir = 'yui-dt-desc';
                    if (Y.Lang.isValue(this._meta_data.data_table_initial_sort)) {
                        meta_sort_key = this._meta_data.data_table_initial_sort.key;
                        meta_sort_dir = this._meta_data.data_table_initial_sort.dir;
                    }
                    start_index = start_index || 0; 
                    sort_key = sort_key || meta_sort_key; 

                    // converts sort dir to yui format
                    if (!dir) {
                        dir = meta_sort_dir;
                    }
                    if (!dir.match(/^yui\-dt\-/)) {
                        dir = 'yui-dt-' + dir;
                    }

                    results = results || this._meta_data.page_count;
                    return {
                        'results': results,
                        'startIndex': start_index,
                        'sort': sort_key,
                        'dir': dir
                    }
                },


                _sendDataTableRequest: function (state) {
                    // Y.log('list::_sendDataTableRequest');
                    // make sure the sort dir is in server format
                    if (state.dir && state.dir.match(/^yui\-dt\-/)) {
                        state.dir = state.dir.substring(7);
                    }

                    this._data_source.sendRequest(Y.QueryString.stringify(state), {
                        success: Y.bind(this._updateDataTableRecords, this),
                        failure: function() { 
                            Y.log('list::_sendDataTableRequest - ' +
                                  'data_source.sendRequest failure'); 
                        },
                        scope: this._data_table,
                        argument: {} // populated at runtime via doBeforeLoadData 
                    });
                },

                _updateDataTableRecords: function (oRequest, oResponse, oPayload) {
                    // Y.log('list::_updateDataTableRecords');
                    this._data_table.onDataReturnSetRows(oRequest, oResponse, oPayload);
                    this.selectRecordFromHistory();
                },

                _afterStateChange: function (e) {
                    // Y.log('list::_afterStateChange - state');
                    var state = this.get('state');
                    // Y.log(Y.merge(state));
                    var pstate = this._data_pager.getState();
                    var tstate = this._data_table.getState();

                    /*
                    Y.log('pstate.recordOffset: ' + pstate.recordOffset + 
                          '  state.startIndex: ' + state.startIndex);
                    Y.log('pstate.rowsPerPage: ' + pstate.rowsPerPage + 
                          '  state.results: ' + state.results);
                    Y.log('tstate.sortedBy.key: ' + tstate.sortedBy.key + 
                          '  state.sort: ' + state.sort);
                    Y.log('tstate.sortedBy.dir: ' + tstate.sortedBy.dir + 
                          '  state.dir: ' + state.dir);
                    Y.log('visible: ' + this.get('visible'));
                    Y.log('has_data: ' + this._has_data);
                    */

                    // compare the vital state with my datatable's current state
                    //  and only update the table if they've changed
                    if (this.get('visible') &&
                        (!this._has_data ||
                         pstate.recordOffset != state.startIndex ||
                         pstate.rowsPerPage != state.results ||
                         (Y.Lang.isValue(tstate.sortedBy) && 
                          tstate.sortedBy.key != state.sort) ||
                         (Y.Lang.isValue(tstate.sortedBy) && 
                          tstate.sortedBy.dir != state.dir))) {
                        this._sendDataTableRequest(state);
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
