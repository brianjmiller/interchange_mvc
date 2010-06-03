YUI.add(
    "ic-manage-widget-function",
    function(Y) {
        var ManageFunction;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageFunction = function (config) {
            ManageFunction.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageFunction,
            {
                NAME: "ic_manage_function",
                ATTRS: {
                    code: {
                        value: null
                    },
                    kind: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageFunction,
            Y.Overlay,
            {
                _meta_data: null,
                _data_source: null,
                _data_source_wrapped: null,
                _data_table: null,

                initializer: function(config) {
                    Y.log("function initializer: " + this.get("code"));

                    // we can't really use the full capabilities of DataSource.IO and the JSON schema
                    // because we need too much information from the actual request itself to build
                    // our data table dynamically, so fetch our object then just use a local data source
                    // for constructing the table

                    var url = "/manage/function/" + this.get("code") + "/0?_mode=config&_format=json";

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

                    this._data_table = new YAHOO.widget.DataTable(
                        contentBox.get("id"),
                        this._meta_data.data_table_column_defs,
                        this._data_source_wrapped,
                        data_table_config
                    );
                    this._data_table.handleDataReturnPayload = function(oRequest, oResponse, oPayload) {
                        oPayload.totalRecords = oResponse.meta.totalRecords;
                        return oPayload;
                    }
                    this._data_table.subscribe("rowMouseoverEvent", this._data_table.onEventHighlightRow);
                    this._data_table.subscribe("rowMouseoutEvent", this._data_table.onEventUnhighlightRow);
                    this._data_table.subscribe("rowClickEvent", this._data_table.onEventSelectRow);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunction = ManageFunction;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
            "yui2-datatable"
        ]
    }
);
