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
        var RendererPanel;

        RendererPanel = function (config) {
            RendererPanel.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererPanel,
            {
                NAME: "ic_renderer_panel",
                ATTRS: {
                    align_to: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            RendererPanel,
            Y.IC.RendererBase,
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
                    Y.log(RendererPanel.NAME + "::initializer");
                    //Y.log(RendererPanel.NAME + "::initializer: " + Y.dump(config));

                    var overlay_args = {
                        headerContent: "",
                        bodyContent:   "Select a control to load content."
                    };
                    this._overlay          = new Y.Overlay( overlay_args );

                    this._data             = config.data;
                    this._built_data_cache = {};
                },

                renderUI: function () {
                    Y.log(RendererPanel.NAME + "::renderUI");

                    // HACK: this is a bit of a hack to allow the overlay to flow
                    //       rather than be positioned absolutely which was causing
                    //       issues
                    this._overlay.get("boundingBox").setStyle("position", "static");

                    this._overlay.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log(RendererPanel.NAME + "::bindUI");

                    this.on(
                        "show_data",
                        Y.bind( this._onShowData, this )
                    );
                },

                syncUI: function () {
                    Y.log(RendererPanel.NAME + "::syncUI");
                },

                _onShowData: function (e, id) {
                    Y.log(RendererPanel.NAME + "::_onShowData");
                    Y.log(RendererPanel.NAME + "::_onShowData - id: " + id);

                    if (! this._built_data_cache[id]) {
                        Y.log(RendererPanel.NAME + "::_onShowData - dumping data[" + id + "]: " + Y.dump(this._data[id]));

                        this._buildData(id);
                    }

                    this._overlay.set("headerContent", this._built_data_cache[id].header);
                    this._overlay.set("bodyContent",   this._built_data_cache[id].body.get("boundingBox"));
                },

                _buildData: function (id) {
                    Y.log(RendererPanel.NAME + "::_buildData");
                    var data = this._data[id];

                    if (Y.Lang.isValue(data.actions)) {
                        var container_constructor = Y.IC.Renderer.getConstructor("Basic");
                        var container = new container_constructor (
                            {
                                _caller: this,
                                data:    ""
                            }
                        );
                        container.render();

                        var header_node = Y.Node.create('<div>' + id + '</div>');
                        Y.each(
                            data.actions,
                            function (action, i, a) {
                                Y.log("action: " + Y.dump(action));
                                header_node.append(action.label);

                                var action_constructor        = Y.IC.Renderer.getConstructor( action.meta._prototype );
                                var action_constructor_config = action.meta._prototype_config;
                                action_constructor_config._caller = this;

                                var action_body = new action_constructor (action_constructor_config);
                                action_body.render();

                                if (i !== 0) {
                                    // TODO: need to hide the others, but there is an issue
                                    //       with the use of display node that should be corrected
                                    action_body.hide();
                                }

                                container.get("contentBox").append( action_body.get("boundingBox") );
                            }
                        );

                        this._built_data_cache[id] = {
                            header: header_node,
                            body:   container
                        };
                    }
                    else if (Y.Lang.isValue(data.content_type)) {
                        var body_constructor        = Y.IC.Renderer.getConstructor( this._data[id].content_type );
                        var body_constructor_config = this._data[id].content;
                        body_constructor_config._caller = this;

                        this._built_data_cache[id] = {
                            body: new body_constructor (body_constructor_config)
                        };
                        this._built_data_cache[id].body.render();

                        if (Y.Lang.isValue(data.label)) {
                            this._built_data_cache[id].header = data.label;
                        }
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.RendererPanel = RendererPanel;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "overlay"
        ]
    }
);
