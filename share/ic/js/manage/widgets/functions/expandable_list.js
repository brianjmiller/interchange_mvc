YUI.add(
    "ic-manage-widget-function-expandable-list",
    function(Y) {

        var ManageFunctionExpandableList;

        ManageFunctionExpandableList = function (config) {
            ManageFunctionExpandableList.superclass.constructor.apply(this, arguments);
        };

        ManageFunctionExpandableList.NAME = "ic_manage_function_expandable_list";

        Y.extend(
            ManageFunctionExpandableList,
            Y.IC.ManageFunctionList,
            {
		        /**
		         * This "getExtendedData" function is passed 'url' (string) and 'success' (function) 
		         * arguments. The success function will be 
		         * given the successful response as an argument and structure the returned data as
		         * a table in a new row expansion. The url argument points to a JSON service
		         **/
		        getExtendedData: function( url, success ){
			
			        /**
			         * This async request is passed a local proxy url with arguments serialized for YQL, 
			         * including the YQL query. YQL will act as the JSON service.
			         **/
			        Y.io(
				        url,
				        {
                            sync: false,
					        success : success,
					        failure : function( o ){
						        Y.log('Failed to get row expansion data','error');
						        
					        }
				        }
			        ); 
			
		        },

                renderUI: function() {
                    Y.log('list renderUI...')
                    var YAHOO = Y.YUI2;

                    var contentBox = this.get("contentBox");

                    // set up a YUI3 data source that we will then wrap
                    // in a YUI2 compatibility container to pass to the
                    // YUI2 data table, presumably when YUI3 gets its
                    // own datatable we can remove this layer

                    this._data_source = new Y.DataSource.IO(
                        {
                            source: "/manage/function/" + this.get("code") + "/0?_mode=data&_format=json&_query_mode=listall&"
                        }
                    );
                    this._data_source.plug(
                        {
                            fn: Y.Plugin.DataSourceJSONSchema,
                            cfg: {
                                schema: {
                                    resultListLocator: 'rows',
                                    resultFields: this._meta_data.data_source_fields,
                                    metaFields: {
                                        totalRecords: 'total_objects'
                                    }
                                }
                            }
                        }
                    );

                    this._data_source_wrapped = new Y.DataSourceWrapper(
                        {
                            source: this._data_source
                        }
                    );

                    var data_table_config = {};

                    if (this._meta_data.data_table_initial_sort) {
                        data_table_config.sortedBy = this._meta_data.data_table_initial_sort;
                    }

                    if (this._meta_data.paging_provider !== "none") {
                        Y.log("setting up pager: " + this._meta_data.paging_provider);
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
                    };

                    contentBox.setContent("");

                    var expansionFormatter  = function(el, oRecord, oColumn, oData) {
                        var cell_element    = el.parentNode;
                        
                        //Set trigger
                        if( oData ){ //Row is closed
                            YAHOO.util.Dom.addClass( cell_element,
                                                     "yui-dt-expandablerow-trigger" );
                        }
                        el.innerHTML = "Expand"; 

                    };

                    Y.log(this._meta_data.data_table_column_defs);
                    this._meta_data.data_table_column_defs[this._meta_data.data_table_column_defs.length - 1].formatter = expansionFormatter;
                    data_table_config.rowExpansionTemplate = 'hello world';

                    this._data_table = new YAHOO.widget.RowExpansionDataTable(
                        contentBox.get("id"),
                        this._meta_data.data_table_column_defs,
                        this._data_source_wrapped,
                        data_table_config
                    );
                    this._data_table.handleDataReturnPayload = function(oRequest, oResponse, oPayload) {
                        oPayload.totalRecords = oResponse.meta.totalRecords;
                        return oPayload;
                    }
                },

                bindUI: function () {
                    this._data_table.on('cellClickEvent', this._data_table.onEventToggleRowExpansion);
                    this._data_table.on('rowMouseoverEvent', this._data_table.onEventHighlightRow);
                    this._data_table.on("rowMouseoutEvent", this._data_table.onEventUnhighlightRow);
                },
		        /**
		         * This "expansionTemplate" function will be passed to the "rowExpansionTemplate" property
		         * of the YUI DataTable to enable the row expansion feature. It is passed an arguments object
		         * which contains context for the record that has been expanded as well as the newly created 
		         * row.
		         **/
		        expansionTemplate: "hello world"

            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunctionExpandableList = ManageFunctionExpandableList;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-function-list"
        ]
    }
);

