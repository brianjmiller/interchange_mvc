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
    "ic-renderer-v2_data_table",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererV2DataTable = Y.Base.create(
            "ic_renderer_v2_data_table",
            Y.IC.RendererBase,
            [],
            {
                _data_source:         null,
                _wrapped_data_source: null,
                _data_table:          null,
                _data_table_config:   null,
                _data_pager:          null,
                _has_data:            false,

                _prev_req:            "",
                _already_sending:     false,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    //
                    // set up a YUI3 data source that we will then wrap in a YUI2 
                    // compatibility container to pass to the YUI2 data table, 
                    // presumably when YUI3 gets its own datatable we can remove
                    // this layer 
                    //
                    var source = this.get("data_url");
                    Y.log(Clazz.NAME + "::initializer - source: " + source);

                    // whether we're dealing with an unfiltered list or
                    // a search is determined by the presence of addtl_args
                    // TODO: need to improve our handling here
                    var addtl_args = this.get("addtl_args");
                    if (Y.Lang.isValue(addtl_args) && addtl_args !== "") {
                        source += "&filter_mode=search&" + addtl_args;
                    }

                    var source_fields = this.get("data_source_fields");
                    if (this.get("data_table_include_options")) {
                        source_fields.push(
                            {
                                key:    "_options",
                            }
                        );
                    }
                    Y.log(Clazz.NAME + "::initializer - source_fields: " + Y.dump(source_fields));

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

                    this._initMaxRows();
                    Y.log(Clazz.NAME + "::renderUI - max_rows: " + this.get("max_rows"));

                    var data_table_config = this._data_table_config = {
                        draggableColumns: false
                    };
                    if (this.get("paging_provider") === "server") {
                        Y.log(Clazz.NAME + "::renderUI - setting dynamic data to true");
                        data_table_config.dynamicData     = true;
                        data_table_config.initialRequest  = "&startIndex=0&results=" + this.get("max_rows");
                        data_table_config.generateRequest = Y.bind( this.dynamicDataGenerateRequest, this );
                    }
                    if (Y.Lang.isValue(this.get("data_table_initial_sort"))) {
                        // make a copy, as config may change the values
                        data_table_config.sortedBy = Y.merge(
                            this.get("data_table_initial_sort")
                        );
                    }

                    if (Y.Lang.isValue(this.get("paging_provider")) && this.get("paging_provider") !== "none") {
                        this._data_pager = new Y.YUI2.widget.Paginator (
                            {
                                alwaysVisible: false,
                                rowsPerPage:   this.get("max_rows"),
                                pageLinks:     20
                            }
                        );

                        data_table_config.paginator = this._data_pager;
                    }

                    Y.log(Clazz.NAME + "::initializer - done");
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._table = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._data_table = new Y.YUI2.widget.DataTable (
                        Y.Node.getDOMNode(this.get("contentBox")),
                        this.get("data_table_column_defs"),
                        this._wrapped_data_source,
                        this._data_table_config
                    );

                    Y.log(Clazz.NAME + "::renderUI - data_table_is_filterable: " + this.get("data_table_is_filterable"));
                    if (this.get("data_table_is_filterable")) {
                        Y.log(Clazz.NAME + "::renderUI - setting up filtering");
                        this.plug(
                            Y.IC.Plugin.TableFilter,
                            {
                                prepend_to: this.get("contentBox")
                            }
                        );
                    }
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");
                    this._data_table.handleDataReturnPayload = Y.bind(
                        this._handleDataReturnPayload, this
                    );
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
                    if (this.get("data_table_include_options")) {
                        //Y.log(Clazz.NAME + "::_bindEvents - installing context menu handling");
                        Y.delegate(
                            "contextmenu",
                            function (e) {
                                Y.log("contextmenu event fired");
                                //Y.log("contextmenu event fired - e: " + Y.dump(e));
                                //Y.log("contextmenu event fired - e.target.id: " + e.target.get("id"));

                                // prevent the browser's own context menu
                                e.preventDefault();

                                var record = this._data_table.getRecord( e.target.get("id") );

                                // build a list of menu items based on the _options data in the record
                                var menu_items = "";
                                Y.each(
                                    record.getData("_options"),
                                    function (option, i, a) {
                                        menu_items += '<li class="yui3-menuitem"><span class="yui3-menuitem-content" id="' + option.code + '-' + Y.guid() + '">' + option.label + '</span></li>';
                                    }
                                );

                                // assemble a menu node to stuff into the overlay
                                var menu_node = Y.Node.create('<div class="yui3-menu"><div class="yui3-menu-content"><ul>' + menu_items + '</ul></div></div>');
                                menu_node.plug(
                                    Y.Plugin.NodeMenuNav
                                );

                                // build and pop up an overlay housing our context menu
                                var overlay = new Y.Overlay (
                                    {
                                        render:        true,
                                        zIndex:        10,
                                        headerContent: "Options",
                                        bodyContent:   menu_node,
                                        xy:            [ e.clientX, e.clientY ]
                                    }
                                );
                                overlay.get("contentBox").addClass("context-menu");

                                // subscribe this after so it has access to "overlay" and "record",
                                // have it handle the clicks on the menu options, it needs to
                                // "close" the overlay
                                menu_node.on(
                                    "click",
                                    function (e) {
                                        //Y.log("menu option chosen");
                                        //Y.log("menu option chosen - e.target.id: " + e.target.get("id"));
                                        overlay.destroy();

                                        var matches         = e.target.get("id").match("^([^-]+)-(?:.+)$");
                                        var selected_action = matches[1];

                                        this._caller.setCurrentRecordWithAction(
                                            record,
                                            selected_action
                                        );
                                    },
                                    this
                                );

                                //
                                // set up mousedown handler to clear our overlay whenever there is
                                // a mouse action somewhere on the page outside of our overlay 
                                // (use mousedown here to also catch any other contextmenu events)
                                //
                                var body_handle = Y.one( document.body ).on(
                                    "mousedown",
                                    function (e) {
                                        //Y.log("body clicked");
                                        body_handle.detach();

                                        if (! overlay.get("contentBox").contains( e.target )) {
                                            overlay.destroy();
                                        }
                                    }
                                );
                            },
                            this._data_table.getContainerEl(),
                            "td",
                            this
                        );
                    }
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");
                    //this.fire("updateData");
                },

                _initMaxRows: function () {
                    Y.log(Clazz.NAME + "::_initMaxRows");

                    // TODO: do we need to include scroll bar height? can we even determine that?
                    //var unit_height = this.get("contentBox").get("height");
                    var unit_height = this.get("height");
                    Y.log(Clazz.NAME + "::_initMaxRows - unit_height: " + unit_height);

                    var magic       = 39; // table header (17) + 1 paginator (22) height
                    //magic          += 21;
                    var total_recs  = this.get("total_objects");
                    var row_height  = 17;

                    // how many rows will fit in my unit?
                    var num_rows = Math.floor(
                        (unit_height - magic) / row_height
                    );
                    //Y.log(Clazz.NAME + "::getMaxNumRows - calculatd rows: " + num_rows);

                    this.set("max_rows", Math.min(num_rows, total_recs));
                },

                _handleDataReturnPayload: function (oRequest, oResponse, oPayload) {
                    Y.log(Clazz.NAME + "::_handleDataReturnPayload");

                    oPayload.totalRecords = oResponse.meta.totalRecords;

                    return oPayload;
                },

                _onUpdateData: function (e) {
                    Y.log(Clazz.NAME + "::_onUpdateData");

                    var req = null
                    if (this.get("paging_provider") === "server") {
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
                    Y.log(Clazz.NAME + "::_onRowSelectEvent");
                    var record = this._data_table.getRecord( this._data_table.getLastSelectedRecord() );

                    this.fire("record_selected", record);
                    //this._caller.setCurrentRecordWithAction(
                        //record,
                        //action_code
                    //);
                },

                // this is a wrapper method to make afterHostMethod used by plugins happy
                // it just passes through to what we'd like to call directly
                dynamicDataGenerateRequest: function (oState, oSelf) {
                    Y.log(Clazz.NAME + "::dynamicDataGenerateRequest");
                    return this._dynamicDataGenerateRequest(oState, oSelf);
                },

                // this method is only used when paging_provider is set to server so that we can
                // do various things before/after the request generation by plugins, etc. and 
                // it is installed as a bounded function in the data table itself
                _dynamicDataGenerateRequest: function (oState, oSelf) {
                    Y.log(Clazz.NAME + "::_dynamicDataGenerateRequest");
                    Y.log(Clazz.NAME + "::_dynamicDataGenerateRequest - oState: " + Y.dump(oState));
                    Y.log(Clazz.NAME + "::_dynamicDataGenerateRequest - oSelf: " + oSelf);

                    var sort, dir, startIndex, results;

                    oState = oState || { pagination: null, sortedBy: null };

                    sort = (oState.sortedBy) ? oState.sortedBy.key : oSelf.getColumnSet().keys[0].getKey();
                    dir  = (oState.sortedBy && oState.sortedBy.dir === oSelf.CLASS_DESC) ? "desc" : "asc";

                    startIndex = (oState.pagination) ? oState.pagination.recordOffset : 0;
                    results    = (oState.pagination) ? oState.pagination.rowsPerPage : null;

                    var result = "&results=" + results + "&startIndex="  + startIndex + "&sort=" + sort + "&dir=" + dir;
                    Y.log(Clazz.NAME + "::_dynamicDataGenerateRequest - result: " + result);

                    this._tmp_dynamic_data_request = result;

                    return result;
                }
            },
            {
                ATTRS: {
                    data_url: {
                        value: null
                    },
                    addtl_args: {
                        value: null
                    },
                    data_source_fields: {
                        value: null
                    },
                    data_table_column_defs: {
                        value: null
                    },
                    data_table_initial_sort: {
                        value: null
                    },
                    data_table_is_filterable: {
                        value:     false,
                        validator: Y.Lang.isBoolean
                    },
                    data_table_include_options: {
                        value:     false,
                        validator: Y.Lang.isBoolean
                    },
                    paging_provider: {
                        value: null
                    },
                    max_rows: {
                        value: null
                    },
                    total_objects: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-v2_data_table-css",
            "ic-renderer-base",
            "datasource",
            "overlay",
            "gallery-datasource-wrapper",
            "yui2-paginator",
            "yui2-datatable",
            "querystring"
        ]
    }
);
