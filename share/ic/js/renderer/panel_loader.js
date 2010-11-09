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
    "ic-renderer-panel_loader",
    function(Y) {
        var RendererPanelLoader;

        RendererPanelLoader = function (config) {
            RendererPanelLoader.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererPanelLoader,
            {
                NAME: "ic_renderer_panel_loader",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererPanelLoader,
            Y.IC.RendererBase,
            {
                // the object that is used as the loader
                _loader: null,

                // the object that will handle display of things loaded
                _panel: null,

                // store a grid node that will house the loader and panel nodes
                _grid_node: null,

                // the loader node contains the object that will be acted upon
                // to cause something to be loaded into the panel node
                _loader_node: null,

                // the panel node contains the object that will get what is needed
                // to be shown when something in the loader is selected
                _panel_node: null,

                initializer: function (config) {
                    Y.log(RendererPanelLoader.NAME + "::initializer");
                    Y.log(RendererPanelLoader.NAME + "::initializer: " + Y.dump(config));

                    //
                    // the loader can be basically any renderer that has elements that
                    // have the "ic_renderer_panel_loader_control" class such that when
                    // they are clicked we tell the panel to load something
                    //
                    // tree and treeble are two examples
                    //
                    var loader_constructor = Y.IC.Renderer.getConstructor(config.loader_config.content_type);
                    Y.log("loader_config: " + Y.dump(config.loader_config));
                    config.loader_config.content._caller = this;

                    this._loader = new loader_constructor (config.loader_config.content);
                    this._loader.render();

                    this._loader_node = Y.Node.create('<div class="yui3-u">Put the loader here</div>');
                    this._loader_node.setContent( this._loader.get("display_node") );

                    var panel_constructor = Y.IC.Renderer.getConstructor('Panel');
                    config.panel_config._caller = this;

                    this._panel = new panel_constructor (config.panel_config);
                    this._panel.render();

                    this._panel_node  = Y.Node.create('<div class="yui3-u">Put the panel here</div>');
                    this._panel_node.setContent( this._panel.get("display_node") );

                    this._grid_node   = Y.Node.create('<div class="yui3-g"></div>');
                    this._grid_node.append(this._loader_node);
                    this._grid_node.append(this._panel_node);

                    this.get("display_node").addClass("renderer_panel_loader");
                },

                renderUI: function () {
                    //Y.log(RendererPanelLoader.NAME + "::renderUI");
                    //Y.log(RendererPanelLoader.NAME + "::renderUI - contentBox: " + this.get("contentBox"));
                    this.get("contentBox").setContent(this._grid_node);
                },

                bindUI: function () {
                    Y.log(RendererPanelLoader.NAME + "::bindUI");

                    this._loader.get("contentBox").delegate(
                        "click",
                        this._onControlClick,
                        ".ic_renderer_panel_loader_control",
                        null,
                        this
                    );
                },

                _onControlClick: function (e, me) {
                    Y.log(RendererPanelLoader.NAME + "::_onControlClick");
                    Y.log(RendererPanelLoader.NAME + "::_onControlClick - this.id: " + this.get("id"));
                    Y.log(RendererPanelLoader.NAME + "::_onControlClick - e.target.id: " + e.target.get("id"));
                    var matches     = this.get("id").match("^([^-]+)-(?:.+)$");
                    var selected_id = matches[1];

                    me._panel.fire("show_data", selected_id);
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererPanelLoader = RendererPanelLoader;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "ic-renderer-panel"
        ]
    }
);
