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
    "ic-renderer-panel",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererPanel = Y.Base.create(
            "ic_renderer_panel",
            Y.IC.RendererBase,
            [],
            {
                _overlay: null,

                // data store keyed on a unique key that will be used when
                // needing to build the data, stores configuration information
                // needed to build the display of the specific data item
                _data: null,

                // cache of previously built data display elements, keyed on
                // same unique key, if an item exists in this cache it will
                // not be built a subsequent time
                _built_data_cache: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._overlay = new Y.Overlay(
                        {
                            headerContent: "",
                            bodyContent:   "Select a control to load content."
                        }
                    );

                    this._data             = config.data;
                    this._built_data_cache = {};
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._overlay          = null;
                    this._data             = null;
                    this._built_data_cache = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    // HACK: this is a bit of a hack to allow the overlay to flow
                    //       rather than be positioned absolutely which was causing
                    //       issues
                    //
                    //       perhaps a better approach is just to use WidgetStdMod
                    //       directly instead of making this an overlay?
                    this._overlay.get("boundingBox").setStyle("position", "static");

                    this._overlay.render( this.get("contentBox") );
                },

                bindUI: function () {
                    Y.log(Clazz.NAME + "::bindUI");

                    this.on(
                        "show_data",
                        Y.bind( this._onShowData, this )
                    );
                },

                _onShowData: function (e, id) {
                    Y.log(Clazz.NAME + "::_onShowData");
                    Y.log(Clazz.NAME + "::_onShowData - id: " + id);

                    if (! this._built_data_cache[id]) {
                        Y.log(Clazz.NAME + "::_onShowData - dumping data[" + id + "]: " + Y.dump(this._data[id]));

                        this._buildData(id);
                    }

                    this._overlay.set("headerContent", this._built_data_cache[id].header);
                    this._overlay.set("bodyContent",   this._built_data_cache[id].body);
                },

                _buildData: function (id) {
                    Y.log(Clazz.NAME + "::_buildData");
                    var data = this._data[id];

                    if (Y.Lang.isValue(data.actions)) {
                        var header_node = Y.Node.create('<div></div>');
                        var body_node   = Y.Node.create('<div></div>');

                        var _caller = this;

                        var count = 0;
                        Y.each(
                            data.actions,
                            function (action, k, obj) {
                                Y.log("action: " + Y.dump(action));
                                header_node.append(action.label);

                                var action_constructor        = Y.IC.Renderer.getConstructor( action.meta._prototype );
                                var action_constructor_config = action.meta._prototype_config;
                                action_constructor_config._caller = this;

                                var action_body = new action_constructor (action_constructor_config);
                                action_body.render( body_node );

                                if (count !== 0) {
                                    action_body.hide();
                                }
                                count++;
                            }
                        );

                        this._built_data_cache[id] = {
                            header: header_node,
                            body:   body_node
                        };
                    }
                    else if (Y.Lang.isValue(data.type)) {
                        this._built_data_cache[id] = {
                            body: Y.IC.Renderer.buildContent( this._data[id], this )
                        };

                        if (Y.Lang.isValue( data.label )) {
                            this._built_data_cache[id].header = data.label;
                        }
                    }
                }
            },
            {
                ATTRS: {
                    align_to: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-panel-css",
            "ic-renderer-base",
            "overlay"
        ]
    }
);
