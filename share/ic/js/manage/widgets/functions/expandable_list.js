YUI.add("ic-manage-widget-function-expandable-list", function (Y) {

    Y.IC.ManageFunctionExpandableList = Y.Base.create(
        "ic_manage_function_expandable_list",           // module identifier  
        Y.IC.ManageFunctionList,                        // what to extend     
        [],                                             // classes to mix in  
        {                                               // overrides/additions

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
            this._data_table.showTableMessage(this._data_table.get("MSG_LOADING"), 
                                              YAHOO.widget.DataTable.CLASS_LOADING);
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

