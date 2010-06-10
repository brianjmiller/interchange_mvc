YUI.add("ic-manage-widget-function-expandable-list", function (Y) {

    Y.IC.ManageFunctionExpandableList = Y.Base.create(
        "ic_manage_function_expandable_list",           // module identifier
        Y.IC.ManageFunctionList,                        // what to extend
        [Y.WidgetParent],                               // classes to mix in
        {                                               // overrides/additions

        _bindDataTableEvents: function () {
            Y.log('expandable_list::bindUI');
            
            Y.IC.ManageFunctionExpandableList.superclass._bindDataTableEvents.call(this);
            this._data_table.on('cellClickEvent', this._data_table.onEventToggleRowExpansion);

            /*  // required for history manager integration
            var pager = this._data_table.configs.paginator;
            // First we must unhook the built-in mechanism... 
            pager.unsubscribe("changeRequest", this._data_table.onPaginatorChangeRequest); 
            // ...then we hook up our custom function 
            pager.subscribe("changeRequest", this._handlePagination, this, true); 

            // Update payload data on the fly for tight integration with latest values from server  
            this._data_table.doBeforeLoadData = function(oRequest, oResponse, oPayload) { 
                var meta = oResponse.meta; 
                Y.log('oRequest...');
                Y.log(oRequest);
                Y.log('oResponse...');
                Y.log(oResponse);
                Y.log('oPayload...');
                Y.log(oPayload);
                oPayload.totalRecords = meta.totalRecords || oPayload.totalRecords; 
                oPayload.pagination = { 
                    rowsPerPage: meta.paginationRowsPerPage || 3, 
                    recordOffset: meta.paginationRecordOffset || 0 
                }; 
                oPayload.sortedBy = { 
                    key: meta.sortKey || "id", 
                    dir: (meta.sortDir) ? "yui-dt-" + meta.sortDir : "yui-dt-asc"
                }; 
                return true; 
            }; 
            */
        },

        /*  // required for history manager integration
        _handlePagination: function (state) { 
            // The next state will reflect the new pagination values 
            // while preserving existing sort values 
            // Note that the sort direction needs to be converted from DataTable format to server value
            var sorted_by = this._data_table.get("sortedBy");
            var new_state = this._generateRequest( 
                state.recordOffset, sorted_by.key, sorted_by.dir, state.rowsPerPage 
            ); 

            // Pass the state along to the Browser History Manager 
            //Y.History.navigate(this.name, new_state); 
            this._updateFromHistory(new_state);
        },
        */

        _initDataTableFormaters: function () {
            var expansionFormatter = function(el, oRecord, oColumn, oData) {
                var cell_element = el.parentNode;
                //Set trigger
                if (oData) { //Row is closed
                    Y.one(cell_element).addClass("yui-dt-expandablerow-trigger");
                }
                el.innerHTML = oData; 
            };
            
            Y.each(this._meta_data.data_table_column_defs, function (v, i, ary) {
                Y.log(v);
                if (v.key === '_options') {
                    v.formatter = expansionFormatter;
                }
            });
        },

        _adjustDataTableConfig: function (data_table_config) {
            data_table_config.rowExpansionTemplate = this.expansionTemplate;
            data_table_config.selectionMode = 'single';
        },

        _initDataTable: function (data_table_config) {
            var YAHOO = Y.YUI2;
            this._data_table = new YAHOO.widget.RowExpansionDataTable(
                this.get('code'),
                this._meta_data.data_table_column_defs,
                this._data_source,
                data_table_config
            );
        },

        /*  // required for history manager integration
        _generateRequest: function (start_index, sort_key, dir, results) { 
            start_index = start_index || 0; 
            sort_key = sort_key || "id"; 
            // Converts from DataTable format "yui-dt-[dir]" to server value "[dir]" 
            dir = (dir) ? dir.substring(7) : "asc";
            results = results || 10; 
            return Y.QueryString.stringify(
                {
                    'results': results,
                    'start_index': start_index,
                    'sort': sort_key,
                    'dir': dir
                }
            );
        },

        _updateFromHistory: function (state) {
            Y.log('list::_updateFromHistory');
            Y.log('history state: ' + state);
            this._data_source.sendRequest(state, {
                success: this._data_table.onDataReturnSetRows,
                failure: function() { Y.log('failure'); }, //this._data_table.onDataReturnSetRows,
                scope: this._data_table,
                argument: {} // Pass in container for population at runtime via doBeforeLoadData 
            });
        },
        */


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
            expansion: {
                value: "bar"
            }
        }
    });
}, '3.1.0' ,{requires:['ic-manage-widget-function-list', 'widget-parent']}); 

