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
    "ic-renderer-tree",
    function(Y) {
        var RendererTree;

        RendererTree = function (config) {
            RendererTree.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererTree,
            {
                NAME: "ic_renderer_tree",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererTree,
            Y.IC.RendererBase,
            {
                _treeview: null,

                initializer: function (config) {
                    Y.log("renderer_tree::initializer");
                    //Y.log("renderer_tree::initializer: " + Y.dump(config));

                    // A treeview is just a plug on a list that we need to construct
                    // ourselves

                },

                renderUI: function () {
                    Y.log("renderer_tree::renderUI");
                    //Y.log("renderer_tree::renderUI - contentBox: " + this.get("contentBox"));
                    this.get("contentBox").setContent("Tree");
                },

                bindUI: function () {
                    Y.log("renderer_tree::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_tree::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererTree = RendererTree;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base"
        ]
    }
);
