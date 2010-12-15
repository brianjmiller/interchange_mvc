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
    "ic-manage-window-content",
    function (Y) {
        var _kind_map = {
            // TODO: dashboard can probably just now be implemented as a Function/Record
            remote_dashboard: Y.IC.ManageWindowContentRemoteDashboard,

            // TODO: should these just be RemoteObject and RemoteClass?
            remote_function:  Y.IC.ManageWindowContentRemoteFunction,

            // with sufficient configuration this could be handled by RemoteFunction
            // ultimately the only thing different is 'object_ui_meta_struct' vs. 'ui_meta_struct'
            remote_record:    Y.IC.ManageWindowContentRemoteRecord
        };

        var Clazz = Y.namespace("IC").ManageWindowContent = Y.Base.create(
            "ic_manage_window_content",
            Y.Widget,
            [ Y.WidgetParent ],
            {
                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this.plug(
                        Y.Plugin.Cache,
                        {
                            uniqueKeys: true,
                            max:        100
                        }
                    );
                    Y.log(Clazz.NAME + "::initializer - cache: " + this.cache);
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    this.on(
                        "showContent",
                        Y.bind( this._onShowContent, this )
                    );
                    this.after(
                        "selectionChange",
                        Y.bind( this._afterSelectionChange, this )
                    );
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");
                },

                _onShowContent: function (e) {
                    Y.log(Clazz.NAME + "::_onShowContent");

                    var config = e.details[0];
                    Y.log(Clazz.NAME + "::_onShowContent - config: " + Y.dump(config));

                    var kind       = config.kind;
                    var kind_class = _kind_map[kind];
                    Y.log(Clazz.NAME + "::_onShowContent - kind: '" + kind + "'");
                    Y.log(Clazz.NAME + "::_onShowContent - kind_class: " + kind_class);

                    //
                    // need to check for cache of this content already shown, if exists
                    // need to just restore it, if doesn't we need to init the content
                    // which does whatever it does, and then display it
                    //
                    // the showing/hiding is handled by selecting/deselecting a particular
                    // child, there is no need to explicitly deselect the existing displayed 
                    // child as that happens automagically by selecting a different one
                    //
                    var cache_key = kind_class.getCacheKey(config.config)
                    Y.log(Clazz.NAME + "::_onShowContent - cache_key: " + cache_key);

                    var cache_entry = this.cache.retrieve(cache_key);
                    Y.log(Clazz.NAME + "::_onShowContent - cache_entry: " + Y.Object.keys(cache_entry));

                    var child;

                    if (! Y.Lang.isValue(cache_entry)) {
                        Y.log(Clazz.NAME + "::_onShowContent - not cached");
                        // TODO: should we clone this?
                        var new_child_config = config.config;

                        // TODO: need to wire in resize stuff so that when our width/height change
                        //       it gets passed to each of the children as well, but there needs
                        //       to be the distinction between advisory width/height (or contained,
                        //       or region) vs. actual width/height in the grandchildren
                        new_child_config.width  = this.get("width");
                        new_child_config.height = this.get("height");
                        Y.log(Clazz.NAME + "::_onShowContent - new_child_config: " + Y.dump(new_child_config));

                        child = new kind_class (new_child_config);
                        Y.log(Clazz.NAME + "::_onShowContent - child from new: " + child);

                        this.add(child);

                        this.cache.add(cache_key, child);
                    }
                    else {
                        child = cache_entry.response;
                        Y.log(Clazz.NAME + "::_onShowContent - child from cache: " + child);
                    }

                    if (Y.Lang.isValue( config.config.action ) && config.config.action !== "") {
                        Y.log(Clazz.NAME + "::_onShowContent - setting action on child: " + config.config.action);

                        child.setAction(config.config.action);
                    }

                    this.selectChild(child.get("index"));

                    Y.log(Clazz.NAME + "::_onShowContent - done");
                },

                _afterSelectionChange: function (e) {
                    Y.log(Clazz.NAME + "::_afterSelectionChange");
                    if (Y.Lang.isValue(e.prevVal)) {
                        e.prevVal.hide();
                    }
                    if (Y.Lang.isValue(e.newVal)) {
                        e.newVal.show();
                    }
                }
            },
            {
                ATTRS: {}
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-css",
            "widget",
            "widget-parent",
            "ic-manage-window-content-remote-dashboard",
            "ic-manage-window-content-remote-function"
        ]
    }
);
