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
    "ic-renderer-record_set",
    function(Y) {
        var TAB_HEIGHT_MAGIC = 38;

        var Clazz = Y.namespace("IC").RendererRecordSet = Y.Base.create(
            "ic_renderer_record_set",
            Y.IC.RendererBase,
            [],
            {
                _tab_view:   null,
                _data_table: null,

                //
                // using our own home grown caching because Y.Cache doesn't provide
                // an API for removing a single record from the cache
                //
                // TODO: switch for tab
                _record_cache: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));
                    this._data_table_config = config.data_table;

                    this._record_cache = {};

                    this._tab_view = new Y.TabView (
                        {
                            height:   this.get("advisory_height"),
                            children: [
                                {
                                    label: "Table"
                                }
                            ]
                        }
                    );

                    var height = this._getTabPanelHeight();
                    Y.log(Clazz.NAME + "::initializer - panel node height: " + height);

                    this._tab_view.item(0).get("panelNode").setStyle("height", height + "px");
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._record_cache = null;
                    this._tab_view     = null;
                    this._data_table   = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._tab_view.render(this.get("contentBox"));

                    this._data_table_config.render = this._tab_view.item(0).get("panelNode");
                    this._data_table_config.height = this._tab_view.item(0).get("panelNode").get("region").height - 8;

                    this._data_table = Y.IC.Renderer.buildContent(
                        {
                            type:   "V2DataTable",
                            config: this._data_table_config
                        }
                    );
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    this._data_table.on(
                        "record_selected",
                        this.onRecordSelected,
                        this
                    );
                    this._tab_view.after(
                        "tab:render",
                        this._afterTabRender,
                        this
                    );
                    this._tab_view.after(
                        "removeChild",
                        this._afterTabRemoved,
                        this
                    );
                    this._tab_view.get("contentBox").delegate(
                        "click",
                        this._onCloseTabClick,
                        ".yui3-ic_renderer_record_set_tab-close",
                        this
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");
                },

                _getTabPanelHeight: function () {
                    return (this.get("advisory_height") - TAB_HEIGHT_MAGIC);
                },

                _afterTabRender: function (e) {
                    Y.log(Clazz.NAME + "::_afterTabRender");

                    var bb = e.target.get("boundingBox");
                    Y.log(Clazz.NAME + "::_afterTabRender - target bounding box: " + bb);

                    bb.addClass("yui3-ic_renderer_record_set_tab-closeable");
                    bb.append('<a class="yui3-ic_renderer_record_set_tab-close" title="Close">x</a>');
                },

                _afterTabRemoved: function (e) {
                    Y.log(Clazz.NAME + "::_afterTabRemoved");

                    // uncache the record
                    Y.some(
                        this._record_cache,
                        function (cache, k, o) {
                            if (e.child.get("id") === cache.tab.get("id")) {
                                Y.log(Clazz.NAME + "::_afterTabRemoved - removing from cache: " + e.child.get("id"));
                                delete o[k];
                            }
                        }
                    );
                },

                _onCloseTabClick: function (e) {
                    Y.log(Clazz.NAME + "::_onCloseTabClick");
                    e.stopPropagation();

                    var tab = Y.Widget.getByNode(e.target);
                    tab.remove();
                },

                onRecordSelected: function (e) {
                    Y.log(Clazz.NAME + "::onRecordSelected");
                    Y.log(Clazz.NAME + "::onRecordSelected - this: " + this);
                    //Y.log(Clazz.NAME + "::onRecordSelected - record: " + Y.dump(e.details[0]));

                    var record = e.details[0];

                    var selected_option;
                    Y.some(
                        record.getData("_options"),
                        function (option, i, a) {
                            if (Y.Lang.isValue(option.is_default) && option.is_default) {
                                selected_option = option;
                                return true;
                            }
                        }
                    );
                    if (! selected_option) {
                        selected_option = record.getData("_options")[0];
                    }

                    var record_config = record._oData._record_config;

                    var cached;
                    if (Y.Lang.isValue(record_config.unique) && Y.Lang.isValue( this._record_cache[ record_config.unique ] )) {
                        cached = this._record_cache[record_config.unique];
                    }

                    if (! cached) {
                        cached = this._record_cache[record_config.unique] = {};

                        // TODO: add ability to do front or back tabbing
                        var index = 1;

                        var tab_args = {
                            label: record_config.label,
                            index: index,
                        };
                        if (Y.Lang.isValue(record_config.meta_url)) {
                            tab_args.content = "Loading...";

                            cached.url = record_config.meta_url;
                        }
                        else {
                            if (Y.Lang.isString(record_config.content)) {
                                tab_args.content = record_config.content;
                            }
                            else {
                                tab_args.panelNode = Y.Node.create("<div></div>");

                                record_config.content.render = tab_args.panelNode;

                                Y.IC.Renderer.buildContent(record_config.content);
                            }
                        }

                        var tab_list = this._tab_view.add(
                            tab_args,
                            index
                        );
                        var tab = tab_list.item(0);

                        var height = this._getTabPanelHeight();
                        tab.get("panelNode").setStyle("height", height + "px");

                        // TODO: need to handle case where record_config.unique doesn't exist
                        cached.tab = tab;

                        if (Y.Lang.isValue(record_config.meta_url)) {
                            this._loadTabContent(cached, selected_option.code);
                        }
                    }

                    this._tab_view.selectChild( cached.tab.get("index") );

                    Y.log(Clazz.NAME + "::onRecordSelected - done");
                },

                _loadTabContent: function (cache_record, action) {
                    Y.log(Clazz.NAME + "::_loadTabContent");
                    //Y.log(Clazz.NAME + "::_loadTabContent - cache_record: " + Y.dump(cache_record));
                    //Y.log(Clazz.NAME + "::_loadTabContent - tab: " + Y.dump(tab.get("data")));
                    Y.io(
                        cache_record.url,
                        {
                            on: {
                                success: Y.bind(
                                    function (record, txnId, response) {
                                        Y.log(Clazz.NAME + "::_loadTabContent - success handler");
                                        var config;

                                        try {
                                            config = Y.JSON.parse(response.responseText);
                                        }
                                        catch (e) {
                                            Y.log(Clazz.NAME + "Can't parse JSON: " + e, "error");
                                            return;
                                        }

                                        record.tab.get("panelNode").setContent("");

                                        var settings = config.renderer;

                                        if (Y.Lang.isValue(action) && ! Y.Lang.isValue(settings.config.action)) {
                                            settings.config.action = action;
                                        }

                                        settings.config.render          = record.tab.get("panelNode");
                                        settings.config.advisory_width  = this.get("width");
                                        settings.config.advisory_height = this.get("height");

                                        Y.IC.Renderer.buildContent(settings);
                                    },
                                    this,
                                    cache_record
                                ),

                                failure: Y.bind(
                                    function (record, txnId, response) {
                                        Y.log(Clazz.NAME + "::_loadTabContent - failure handler");
                                        record.tab.get("panelNode").setContent("Error occurred retrieving meta data");
                                    },
                                    this,
                                    cache_record
                                )
                            }
                        }
                    );
                    Y.log(Clazz.NAME + "::_loadTabContent - done");
                }
            },
            {
                ATTRS: {}
            }
        );

        Y.IC.Renderer.registerConstructor("RecordSet", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-record_set-css",
            "ic-renderer-base",
        ]
    }
);
