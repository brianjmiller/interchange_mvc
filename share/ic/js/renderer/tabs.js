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
        var RendererTabs;

        RendererTabs = function (config) {
            RendererTabs.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererTabs,
            {
                NAME: "ic_renderer_tabs",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererTabs,
            Y.IC.RendererBase,
            {
                _tab_view: null,

                initializer: function (config) {
                    Y.log("renderer_tabs::initializer");
                    //Y.log("renderer_tabs::initializer: " + Y.dump(config));

                    this._tab_view = new Y.TabView ();

                    Y.each(
                        config.tabs,
                        function (v, i, a) {
                            Y.log("adding tab: " + i);

                            // build content based on the content_type of the tab meta
                            var tab_add_args = {
                                label:   v.label,
                                index:   i,
                            };
                            if (v.content_type) {
                                Y.log("content_type: " + v.content_type);
                                var content_constructor = Y.IC.Renderer.getConstructor(v.content_type);
                                v.content._caller = this;

                                var content = new content_constructor (v.content);
                                content.render();

                                Y.log("content display node: " + content.get("boundingBox"));
                                tab_add_args.panelNode = content.get("boundingBox");
                            }
                            else {
                                tab_add_args.content = v.content;
                            }

                            Y.dump("tab_add_args: " + Y.dump(tab_add_args));
                            this.add(tab_add_args, i);
                        },
                        this._tab_view
                    );
                },

                renderUI: function () {
                    Y.log("renderer_tabs::renderUI");
                    Y.log("renderer_tabs::renderUI - contentBox: " + this.get("contentBox"));

                    this._tab_view.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_tabs::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_tabs::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererTabs = RendererTabs;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "tabview"
        ]
    }
);
