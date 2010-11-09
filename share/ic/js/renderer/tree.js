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
                    Y.log("renderer_tree::initializer: " + Y.dump(config));

                    // a treeview is just a plug on a list that we need to construct ourselves
                    this._treeview = Y.Node.create('<ol id="' + Y.guid() + '"></ol>');

                    Y.each(
                        config.data,
                        function (data_node, i, a) {
                            this._treeview.append( this._datanodeToNodes(data_node) );
                        },
                        this
                    );

                    this._treeview.plug( Y.Plugin.TreeviewLite );
                },

                _datanodeToNodes: function (data_node) {
                    var span_node = Y.Node.create('<span id="' + data_node.id + '-' + this._treeview.get("id") + '">' + data_node.label + '</span>');
                    if (Y.Lang.isValue(data_node.add_class)) {
                        span_node.addClass(data_node.add_class);
                    }

                    var li_node   = Y.Node.create('<li></li>');
                    li_node.append(span_node);

                    if (data_node.branches) {
                        var ul_node = Y.Node.create('<ul></ul>');
                        li_node.append(ul_node);

                        Y.each(
                            data_node.branches,
                            function (branch, i, a) {
                                ul_node.append( this._datanodeToNodes(branch) );
                            },
                            this
                        );
                    }

                    return li_node;
                },

                renderUI: function () {
                    Y.log("renderer_tree::renderUI");
                    //Y.log("renderer_tree::renderUI - contentBox: " + this.get("contentBox"));
                    this.get("contentBox").setContent(this._treeview);
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
            "ic-renderer-base",
            "gallery-treeviewlite"
        ]
    }
);
