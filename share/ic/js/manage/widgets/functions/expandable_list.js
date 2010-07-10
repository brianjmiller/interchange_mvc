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

YUI.add("ic-manage-widget-function-expandable-list", function (Y) {

    Y.IC.ManageFunctionExpandableList = Y.Base.create(
        "ic_manage_function_expandable_list",           // module identifier  
        Y.IC.ManageFunctionList,                        // what to extend     
        [],                                             // classes to mix in  
        {                                               // overrides/additions

        _fitted: false,

        _bindDataTableEvents: function () {
            // Y.log('expandable_list::_bindDataTableEvents');
            Y.IC.ManageFunctionExpandableList.superclass._bindDataTableEvents.call(this);
            if (this.get('expandable')) {
                this._data_table.on('cellClickEvent', this._data_table.onEventToggleRowExpansion);
            }
        },

        _initDataTableFormaters: function () {
            var expansionFormatter = function(el, oRecord, oColumn, oData) {
                var cell_element = el.parentNode;
                //Set trigger
                if (oData) { //Row is closed
                    Y.one(cell_element).addClass("yui-dt-expandablerow-trigger");
                }
                el.innerHTML = oData; 
            };
            
            if (this.get('expandable')) {
                Y.each(this._meta_data.data_table_column_defs, function (v, i, ary) {
                    if (v.key === '_options') {
                        v.formatter = expansionFormatter;
                    }
                });
            }
        },

        _adjustDataTableConfig: function (data_table_config) {
            data_table_config.rowExpansionTemplate = this.expansionTemplate;
            data_table_config.selectionMode = 'single';
            data_table_config.initialLoad = false;
        },

        _initDataTable: function (data_table_config) {
            // Y.log('expandable_list::_initDataTable');
            // Y.log(this._data_source);
            var YAHOO = Y.YUI2;
            this._data_table = new YAHOO.widget.RowExpansionDataTable(
                this.get('code'),
                this._meta_data.data_table_column_defs,
                this._data_source,
                data_table_config
            );
            this._data_table.showTableMessage(
                this._data_table.get("MSG_LOADING"), 
                YAHOO.widget.DataTable.CLASS_LOADING
            );
        },

        _sendDataTableRequest: function (state) {
            // Y.log('expandable_list::_sendDataTableRequest - has_data:' + this._has_data);
            Y.IC.ManageFunctionExpandableList.superclass
                ._sendDataTableRequest.apply(this, arguments);
            this._fitted = false;
            if (this._has_data) this.fitToContainer();
        },


        hide: function () {
            // Y.log('expandable_list::hide - setting has_data and fitted to false');
            Y.IC.ManageFunctionExpandableList.superclass
                .hide.apply(this, arguments);
            this._has_data = false;
            this._fitted = false;
        },

        show: function () {
            // Y.log('expandable_list::show - fitted:' + this._fitted);
            Y.IC.ManageFunctionExpandableList.superclass
                .show.apply(this, arguments);
            if (!this._fitted) this.fitToContainer();
        },

        fitToContainer: function (container) {
            // Y.log('BEGIN expandable_list::fitToContainer');
            var dt = this._data_table;
            if (dt) {
                if (!container) {
                    // looking for the layout unit,
                    //  can get it from the ManageContainer
                    var mc = this.get('boundingBox')
                        .ancestor('div.yui3-ic_manage_container');
                    var widget = Y.Widget.getByNode(mc);
                    container = widget.get('layout_unit');
                }
                dt.validateColumnWidths();
                var dt_node = this.get('contentBox')
                    .one('div.yui-dt-scrollable');
                var dt_height = dt_node.get('region').height;
                var unit_body = Y.one(container.get('wrap'))
                    .one('div.yui-layout-bd');
                var unit_height = unit_body.get('region').height;
                var magic = 58; // table header + paginator height?
                var state = this.get('state');
                var results = Number(state.results);
                var total_recs = this._meta_data.total_objects;
                /*
                Y.log('dt_height: ' + dt_height +
                      ' unit_height: ' + unit_height +
                      ' results: ' + results +
                      ' total_recs: ' + total_recs);
                */
                if (dt_height > unit_height) {
                    // Y.log('shrink the table to fit');
                    dt.set('height', (unit_height - magic) + 'px');
                    // determine the number of visible rows
                    var tr = Y.one(dt.getFirstTrEl());
                    if (tr) {
                        var row_height = tr.get('region').height;
                        var bd_height = dt_node.one('div.yui-dt-bd')
                            .get('region').height;
                        var recs_per_page = Math.round(bd_height / row_height);
                        if (results != recs_per_page) {
                            // if there's a selected record, 
                            //  calculate the recordOffset so that it
                            //  becomes the top row of the new page
                            var offset = state.startIndex || 0;
                            var srow = this._data_table.getSelectedRows()[0];
                            /*
                            Y.log('recs_per_page -> offset -> srow');
                            Y.log(recs_per_page);
                            Y.log(offset);
                            Y.log(srow);
                            */
                            if (srow) {
                                var ri = this._data_table.getRecordIndex(srow);
                                offset = Math.floor(ri / recs_per_page) * recs_per_page
                                // Y.log('offset = ' + offset);
                            }
                            this.setNewPaginator(recs_per_page, offset);
                        }
                        this._fitted = true;
                        // Y.log('notifying history the new results after shriking.');
                        this._notifyHistory();
                    }
                    else {
                        // there are no visible rows, so not fitted
                        this._fitted = false;
                    }
                }

                else if (dt_height < unit_height) {
                    // Y.log('not as big as my unit, try to expand');
                    var tr = Y.one(dt.getFirstTrEl());
                    var new_height;
                    if (tr) {
                        var row_height = tr.get('region').height;
                        var max_rows = Math.round(
                            (unit_height - magic) / row_height
                        );
                        max_rows = max_rows > total_recs ? 
                            total_recs : max_rows;
                        new_height = (max_rows * row_height) + magic;
                        if (new_height > unit_height) 
                            new_height = unit_height;
                        // Y.log('fitted with max_rows:' + max_rows);
                        this._fitted = true;
                    }
                    else {
                        // Y.log('no visible rows, so set height to the ' +
                        //       'unit_height, be unfitted, and try again');
                        new_height = unit_height;
                        this._fitted = false;
                    }
                    dt.set('height', (new_height - magic) + 'px');
                    if (results != max_rows) {
                        // Y.log('notifying history new results after expansion.')
                        // do i need to get new records?
                        if (!(results > total_recs) &&
                            (results < total_recs)) { 
                            state.results = max_rows;
                            state.startIndex = 0;
                            // this._sendDataTableRequest(state);
                            this._notifyHistory();
                        }
                        else {
                            this._notifyHistory();
                        }
                    }
                }

                else {
                    // Y.log('notifying history with no change.');
                    this._notifyHistory();
                }
            }
        },

		/**
		 * This "expansionTemplate" function will be passed to the "rowExpansionTemplate" property
		 * of the YUI DataTable to enable the row expansion feature. It is passed an arguments object
		 * which contains context for the record that has been expanded as well as the newly created 
		 * row.
		 **/
		expansionTemplate: function(o) {
            var _options = Y.Node.create(o.data.getData('_options'));
            // everything below is repeated from container.js - not at all dry...
            var matches    = _options.get("id").match("^([^-]+)-([^-]+)(?:-([^-]+)-(.+))?$");
            var kind       = matches[2] || '';
            var sub_kind   = matches[3] || '';
            var addtl_args = matches[4] || '';
            var config = {
                kind: kind,
                sub_kind: sub_kind,
                args: addtl_args
            };
            var splits = config.args.split("-", 2);
            var code = splits[0];
            var addtl_args = splits[1] + "";
            var widget = new Y.IC.ManageFunctionDetail(
                {
                    code: code,
                    addtl_args: addtl_args
                }
            );
            widget.render(o.liner_element);
         }
    }, 
    {
        NAME: 'ic_manage_widget_function_expandable_list',
        ATTRS : {            
            expandable: {
                value: true
            }
        }
    });
},
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-function-list",
            "ic-manage-widget-function-detail",
            "base-base",
            "rowexpansion"
        ]
    }
);

