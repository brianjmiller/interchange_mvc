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
    "ic-renderer-tabs",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererTabs = Y.Base.create(
            "ic_renderer_tabs",
            Y.IC.RendererBase,
            [],
            {
                _config:   null,
                _tab_view: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._config = config.data;
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._config   = null;
                    this._tab_view = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    var children = [];

                    Y.each(
                        this._config,
                        function (v, i, a) {
                            Y.log(Clazz.NAME + "::renderUI - adding tab: " + i);

                            var tab_add_args = {
                                label:     v.label,
                                index:     i,
                                panelNode: Y.Node.create("<div></div>")
                            };
                            v.content.render = tab_add_args.panelNode;

                            Y.IC.Renderer.buildContent(v.content);

                            this.push(tab_add_args);
                        },
                        children
                    );

                    this._tab_view = new Y.TabView (
                        {
                            render:   this.get("contentBox"),
                            children: children
                        }
                    );
                }
            },
            {
                ATTRS: {}
            }
        );

        Y.IC.Renderer.registerConstructor("Tabs", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-tabs-css",
            "ic-renderer-base",
            "tabview"
        ]
    }
);
