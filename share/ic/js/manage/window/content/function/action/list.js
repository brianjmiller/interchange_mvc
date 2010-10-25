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
    "ic-manage-window-content-function-action-list",
    function(Y) {
        var ManageWindowContentFunctionActionList;

        ManageWindowContentFunctionActionList = function (config) {
            ManageWindowContentFunctionActionList.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageWindowContentFunctionActionList,
            {
                NAME: "ic_manage_content_function_action_list",
                ATTRS: {
                    layout: {
                        value: null
                    },
                    current_record: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageWindowContentFunctionActionList,
            Y.IC.ManageWindowContentFunctionActionBase,
            {
                _data_table_node:    null,
                _data_table:         null,
                _record_header_node: null,
                _record_node:        null,

                // TODO: make this a smart cache
                _record_cache:    null,

                initializer: function (config) {
                    Y.log("manage_window_content_function_action_list::initializer");
                    //Y.log("manage_window_content_function_action_list::initializer: " + Y.dump(config));

                    this._record_cache = {};

                    // set up nodes to render the objects to, we'll then use the nodes
                    // for loading up the chain
                    this._data_table_node    = Y.Node.create('<div class="action_list_data_table_node"></div>');
                    this._record_header_node = Y.Node.create('<div class="action_list_record_header_node"></div>');
                    this._record_node        = Y.Node.create('<div class="action_list_record_node"></div>');

                    this._data_table = new Y.IC.ManageWindowContentFunctionActionListTable (
                        {
                            _caller:   this,
                            render_to: this._data_table_node._node,
                            meta:      {
                                data_source_fields:         this.get("meta").data_source_fields,
                                data_table_column_defs:     this.get("meta").data_table_column_defs,
                                data_table_include_options: this.get("meta").data_table_include_options,
                                data_table_initial_sort:    this.get("meta").data_table_initial_sort,
                                paging_provider:            this.get("meta").paging_provider,
                                page_count:                 this.get("meta").page_count,
                                total_objects:              this.get("meta").total_objects
                            }
                        }
                    );
                    if (this.get("meta").data_table_is_filterable) {
                        Y.log("manage_window_content_function_action_list::initializer - plugging tablefilter");
                        this._data_table.plug(
                            Y.IC.Plugin.TableFilter,
                            {
                                prepend_to: this._data_table_node,
                            }
                        );
                    }

                    this.after(
                        "layoutChange",
                        Y.bind(this._afterLayoutChange, this)
                    );
                    this.after(
                        "current_recordChange",
                        Y.bind(this._afterCurrentRecordChange, this)
                    );
                },

                _onLoad: function (e) {
                    // TODO: if they want a specific record displayed we should get it here
                    //       and set it locally, and correct for the layout in that case
                    this.set("layout", "full");

                    Y.IC.ManageWindowContentFunctionActionList.superclass._onLoad.apply(this, arguments);
                },

                _afterLayoutChange: function (e) {
                    //Y.log("manage_window_content_function_action_list::_afterLayoutChange");
                    this._parts = {};

                    var this_layout = this.get("layout");
                    //Y.log("manage_window_content_function_action_list::_afterLayoutChange - this_layout: " + this_layout);

                    // TODO: stuffing the data table in a particular part likely means
                    //       we need to make sure it is fit to that part

                    if (this_layout === "full") {
                        this._parts.center_body = this._data_table_node;
                    }
                    else if (this_layout === "h_divided") {
                        this._parts.top_body      = this._data_table_node;
                        this._parts.center_header = this._record_header_node;
                        this._parts.center_body   = this._record_node;
                    }
                    else {
                        //Y.log("manage_window_content_function_action_list::_onLoad - Unrecognized layout: " + this_layout, "error");
                    }

                    this._caller._loadPieces(this.get("layout"));
                },

                setCurrentRecordWithAction: function (row, action) {
                    //Y.log("manage_window_content_function_action_list::setCurrentRecordWithAction");
                    this.set("current_record", row);
                    this._record.set("action", action);
                },

                _afterCurrentRecordChange: function (e) {
                    //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange");

                    if (this._record) {
                        //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange - disabling previous record");
                        this._record.set("disabled", "true");
                    }

                    var pk = {};

                    Y.each(
                        this.get("current_record").getData("_pk_settings"),
                        function (v, i, a) {
                            pk[v.field] = v.value;
                        }
                    );

                    //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange - loading new record: " + Y.dump(pk));
                    this._loadRecord(pk);

                    //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange - enabling new record");
                    this._record.set("disabled", false);

                    //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange - setting my content");
                    this._record_header_node.setContent( this._record.get("header_node") );
                    this._record_node.setContent( this._record.get("display_node") );

                    if (this.get("layout") !== "h_divided") {
                        //Y.log("manage_window_content_function_action_list::_afterCurrentRecordChange - setting layout to h_divided");
                        this.set("layout", "h_divided");
                    }

                    //Y.log("manage_window_content_function_action_list::displayRecord - done");
                },

                _loadRecord: function (pk) {
                    //Y.log("manage_window_content_function_action_list::_onLoadRecord");
                    //Y.log("manage_window_content_function_action_list::_onLoadRecord + pk: " + Y.dump(pk));

                    var _record_cache_key = Y.QueryString.stringify(pk);

                    if (this._record_cache[_record_cache_key]) {
                        //Y.log("manage_window_content_function_action_list::_onLoadRecord - using cached record");
                        this._record = this._record_cache[_record_cache_key];
                    }
                    else {
                        //Y.log("manage_window_content_function_action_list::_onLoadRecord - building new record");
                        this._record = new Y.IC.ManageWindowContentFunctionActionListRecord (
                            {
                                _caller: this,
                                pk:      pk
                            }
                        );

                        this._record_cache[_record_cache_key] = this._record;
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindowContentFunctionActionList = ManageWindowContentFunctionActionList;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-function-action-list-css",
            "ic-manage-window-content-function-action-base",
            "node",
            "querystring",
            "ic-plugin-tablefilter",
            "ic-manage-window-content-function-action-list-table",
            "ic-manage-window-content-function-action-list-record"
        ]
    }
);
