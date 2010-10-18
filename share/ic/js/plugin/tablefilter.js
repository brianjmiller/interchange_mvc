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
    "ic-plugin-tablefilter",
    function(Y) {
        Y.namespace("IC.Plugin");

        var TableFilter = function (config) {
            TableFilter.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            TableFilter,
            {
                NAME:  'ic_manage_plugin_tablefilter',
                NS:    'tablefilter',
                ATTRS: {}
            }
        );

        Y.extend (
            TableFilter,
            Y.Plugin.Base,
            {
                //
                // the data table that will be affecting us, and that we'll be causing to get filtered
                //
                _reference_data_table: null,

                //
                // store the local custom table that will sit on top of the data table to be filtered
                // it has the same number of columns as the data table itself
                //
                _filter_table_node: null,

                // store a list of filters, one per column this way we can track filters
                // so that they can be adjusted in various ways when the underlying table
                // column itself is adjusted
                _filters: null,

                // whether or not our local table has been inserted above the data table
                _rendered: false,

                // where to put our filter table
                _prepend_to: null,

                initializer: function (config) {
                    Y.log('plugin_tablefilter::initializer');
                    if (config.prepend_to) {
                        this._prepend_to = config.prepend_to;
                    }

                    this._reference_data_table = this.get("host")._data_table;
                    this._filters              = {};

                    // TODO: set up an event handler to build our filter table
                    //       once the data table has been rendered

                    this._initFilterTable();
                    this._bindFilter();
                }, 

                destructor: function () {
                    Y.log('plugin_tablefilter::destructor');

                    this._reference_data_table = null;
                    this._filter_table_node    = null;
                    this._filters              = null;
                    this._prepend_to           = null;

                    this._detachFilter();
                },

                _initFilterTable: function () {
                    Y.log('plugin_tablefilter::_initFilterTable');
                    var tr    = Y.Node.create('<tr></tr>');
                    var tbody = Y.Node.create('<tbody></tbody>');
                    tbody.append(tr);

                    var table = Y.Node.create('<table></table>');
                    table.append(tbody);

                    this._filter_table_node = table;

                    //
                    // build a column filter for each column in the reference table
                    // then we'll individually show the ones we need to
                    //
                    Y.each(
                        this._reference_data_table.getColumnSet().flat,
                        function (col, i, columns) {
                            // build a column filter and stash it locally
                            var column_filter = new Y.IC.Plugin.TableFilter.ColumnFilter (
                                {
                                    group:  this,
                                    column: col
                                }
                            );
                            this._filters[col.field] = column_filter;

                            // now actually append it if it is currently shown
                            if (! columns[i].hidden) {
                                tr.append(column_filter._td);
                            }
                        },
                        this
                    );

                    if (this._prepend_to) {
                        this._prepend_to.prepend(this._filter_table_node);
                        this._rendered = true;
                    }
                },

                _bindFilter: function () {
                    Y.log('plugin_tablefilter::_bindFilter');

                    //
                    // depending on whether the data table is configured with dynamic data
                    // we'll either do an on response callback handler (client side)
                    // or we'll munge the request itself (server side)
                    //

                    if (this._reference_data_table.get("dynamicData")) {
                        this.afterHostMethod(
                            "_dynamicDataGenerateRequest",
                            this.filterDynamicData
                        );
                    }
                    else {
                        this.get("host")._data_source.on(
                            "response",
                            Y.bind(
                                this.filterNonDynamicData,
                                this
                            )
                        );
                    }
                },

                _detachFilter: function () {
                    Y.log('plugin_tablefilter::_detachFilter');
                },

                getActiveFilters: function () {
                    Y.log("plugin_tablefilter::getActiveFilters");

                    var columns = this._reference_data_table.getColumnSet().flat;

                    // build a list of active filters, specifically those whose column is not hidden
                    var active_filters = [];

                    Y.each(
                        columns,
                        function (column, i, a) {
                            if (! column.hidden) {
                                active_filters.push( this._filters[column.field] );
                            }
                        },
                        this
                    );

                    return active_filters;
                },

                _submitFilter: function (e) {
                    Y.log('plugin_tablefilter::_submitFilter');

                    if (this._reference_data_table.get("dynamicData")) {
                        this.get("host").fire("updateData");
                    }
                    else {
                        Y.log('plugin_tablefilter::_submitFilter - clearing records');
                        var record_set  = this._reference_data_table.getRecordSet();

                        var active_filters = this.getActiveFilters();

                        var cur_records = record_set.getRecords();
                        var new_records = [];

                        // loop over all of the current records testing against the set of active filters,
                        // as soon as one indicates that the record should be kept then stop the check and
                        // add the record to the list of those to keep
                        Y.each(
                            cur_records,
                            function (record, i, a) {
                                Y.log("testing row: " + i);

                                var filter_result = Y.some(
                                    active_filters,
                                    function (filter, ii, ia) {
                                        Y.log("against filter: " + ii + " - " + filter._reference_column.field);

                                        if (filter.keep(record._oData)) {
                                            Y.log("record kept (ending inner loop)");
                                            return true;
                                        }
                                        return false;
                                    },
                                    this
                                );
                                if (filter_result) {
                                    Y.log("adding record to new_records: " + i);
                                    this.push(record._oData);
                                }
                            },
                            new_records
                        );
                        record_set.replaceRecords(new_records);

                        Y.log("setting new records length: " + new_records.length);
                        this.get("host")._data_pager.setState(
                            {
                                totalRecords: new_records.length
                            }
                        );

                        this._reference_data_table.render();
                    }
                },

                //
                // these two methods should really become a single method
                // on each of two subclasses, but for time saving purposes
                // I've handled it this way for now, besides I'm not sure
                // what other instances will be encountered in the future
                //

                // TODO: this needs to leverage the code in submit filter
                //
                // this is an event handler for the "response" event of the
                // YUI3 data source that underlies the wrapped data source
                // provided to the data table
                filterNonDynamicData: function (e) {
                    Y.log("plugin_tablefilter::filterNonDynamicData");

                    var raw_results = e.details[0].response.results;
                    var new_results = e.details[0].response.results = [];

                    Y.each(
                        raw_results,
                        function (row, i, a) {
                            Y.log("testing row " + i + " against filter");

                            this.push(row);
                        },
                        new_results
                    );

                    return;
                },

                // this is a method modifier wrapped around the generate request
                // method called on our host to generate the URL string needed
                // to retrieve a page of data, the request as build so far is
                // stored temporarily in the object, this function adjusts it
                // (if necessary) and then changes the return value to the new
                // URI query string needed by the server to filter results
                filterDynamicData: function () {
                    Y.log("plugin_tablefilter::filterDynamicData");

                    var new_return = this.get("host")._tmp_dynamic_data_request;
                    Y.log("plugin_tablefilter::filterDynamicData - starting uri string: " + new_return);

                    //
                    // run through each field in the tablefilter form
                    // and build a list of &search_by[]=field%3Dop&field=value params
                    //
                    var args = [];

                    Y.each(
                        this.getActiveFilters(),
                        function (filter, i, a) {
                            var snippet = filter.getURISnippet();
                            if (snippet !== "") {
                                args.push(snippet);
                            }
                        }
                    );

                    // only adjust the return if there was something to add
                    if (args.length) {
                        var addition = "&filter_mode=search" + "&" + args.join("&");
                        Y.log("plugin_tablefilter::_buildFilterArgs - addition: " + addition);

                        new_return += addition;

                        Y.log("plugin_tablefilter::filterDynamicData - ending uri string: " + new_return);
                        return new Y.Do.AlterReturn ('', new_return);
                    }

                    return;
                }
            }
        );

        Y.IC.Plugin.TableFilter = TableFilter;

        var ColumnFilter = function (config) {
            ColumnFilter.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ColumnFilter,
            {
                NAME: "ic_manage_plugin_tablefilter_columnfilter",
                ATTRS: {
                }
            }
        );

        Y.extend(
            ColumnFilter,
            Y.Base,
            {
                // the filter group we belong to
                _filter_group: null,

                // the column in the data table that we'll need to "mimic"
                _reference_column: null,

                // our storage cell
                _td:               null,

                // our inputs that are combined to make the URI string snippet
                // or test against a local record
                _controls:         null,

                initializer: function (config) {
                    Y.log("plugin_tablefilter_columnfilter::initializer");

                    this._filter_group     = config.group;
                    this._reference_column = config.column;

                    // TODO: move the padding into a class stylesheet
                    this._td = Y.Node.create('<td style="padding: 0 7px"></td>');

                    var name  = this._reference_column.field + '_filter';
                    Y.log("name: " + name);

                    this._controls = [];

                    // TODO: need to set the width on the input type based on the column width
                    var input_node = Y.Node.create('<input type="text" name="' + name + '" />');
                    this._controls.push(input_node);

                    // TODO: can this be delegated?
                    input_node.on(
                        "key",
                        Y.bind(
                            this._filter_group._submitFilter,
                            this._filter_group
                        ),
                        'down:13'
                    );
                    this._td.append(input_node);

                    this._bindEvents();
                },

                _bindEvents: function () {
                    Y.log("plugin_tablefilter_columnfilter::_bindEvents");
                    // resize
                    // hide/show
                    // switch places (i.e. drag)
                },

                // this method is used for non-dynamicData conditions (when the client should do the filtering)
                keep: function (record) {
                    Y.log("plugin_tablefilter_columnfilter::keep");

                    return true;
                },

                // this method is used for dynamicData conditions (when the server will do the filtering)
                getURISnippet: function () {
                    Y.log("plugin_tablefilter_columnfilter::getURISnippet");
                    var args = [];

                    Y.each(
                        this._controls,
                        function (control, i, controls) {
                            Y.log("plugin_tablefilter_columnfilter::getURISnippet - control: " + i);

                            var parsed_value = this._parseControlValue( control.get('value') );
                            Y.log("plugin_tablefilter_columnfilter::getURISnippet - parsed_value: " + Y.dump(parsed_value));

                            if (parsed_value.values && parsed_value.values.length > 0) {
                                Y.log("plugin_tablefilter_columnfilter::getURISnippet - parsed_value.values.length: " + parsed_value.values.length);
                                parsed_value.value = parsed_value.values.join(',');
                                parsed_value.op    = parsed_value.ops.join('-');

                                var name = control.get('name');

                                // strip off '_filter' (the 'name.length - 7')
                                var field_name = name.substring(0, name.length - 7);
                                args.push(
                                    'search_by[]=' + encodeURIComponent(field_name + '=' + parsed_value.op) + '&' + field_name + '=' + encodeURIComponent(parsed_value.value)
                                );
                            }
                        },
                        this
                    );

                    var string = "";
                    if (args.length) {
                        string = args.join("&");
                    }

                    return string;
                },

                _parseControlValue: function (filter) {
                    Y.log("plugin_tablefilter_columnfilter::_parseControlValue");

                    //
                    // there is a mapping between operators, so that the user 
                    // can input "<= 300" into the filter field.
                    // ~ = ilike, = = eq, < = lt, <= = le, etc.
                    //
                    // we also allow multiple operators, and simply separate the
                    // addition with a comma:
                    // <= 300, >= 400
                    //
                    // defaults to an operator of ilike against the value as a whole

                    var op_map = {
                        '~':  'ilike',
                        '~=': 'like',
                        '=':  'eq',
                        '!=': 'ne',
                        '<':  'lt',
                        '<=': 'le',
                        '>':  'gt',
                        '>=': 'ge'
                    };
                    var re = /^\s*(~|~=|=|!=|<|<=|>|>=)\s*(.+)\s*$/i;

                    // TODO: adjust this delimiter to be something better,
                    //       perhaps ,,
                    var subfilters = filter.split(/\s*,\s*/);
                    var ops        = [];
                    var values     = [];

                    Y.each(
                        subfilters,
                        function (subfilter) {
                            var results = re.exec(subfilter);

                            if (results !== null && results.length === 3) {
                                ops.push(
                                    op_map[ results[1] ]
                                );
                                values.push( results[2] );
                            }
                            else if (subfilter !== "") {
                                values.push(subfilter);
                                ops.push('ilike');
                            }
                        }
                    );

                    var result = {
                        values: values,
                        ops:    ops
                    };

                    return result;
                }

            }
        );

        Y.IC.Plugin.TableFilter.ColumnFilter = ColumnFilter;
    },
    "@VERSION@",
    {
        requires: [
            "ic-plugin-tablefilter-css",
            "plugin",
            "event-key"
        ]
    }
);
