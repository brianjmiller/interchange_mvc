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
    "ic-renderer",
    function(Y) {
        Y.namespace("IC.Renderer");
        var _constructor_map = {
            Basic:    Y.IC.RendererBasic.prototype.constructor,
            Grid:     Y.IC.RendererGrid.prototype.constructor,
            Form:     Y.IC.RendererForm.prototype.constructor,
            Tabs:     Y.IC.RendererTabs.prototype.constructor,
            Tree:     Y.IC.RendererTree.prototype.constructor,
            Table:    Y.IC.RendererTable.prototype.constructor,
            Treeble:  Y.IC.RendererTreeble.prototype.constructor,
            KeyValue: Y.IC.RendererKeyValue.prototype.constructor,
            Chart:    Y.IC.RendererChart.prototype.constructor
        };

        Y.IC.Renderer.getConstructor = function (key) {
            Y.log('Y.IC.Renderer::getConstructor');
            Y.log('Y.IC.Renderer::getConstructor - key: ' + key);

            return _constructor_map[key];
        };
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-basic",
            "ic-renderer-grid",
            "ic-renderer-form",
            "ic-renderer-tabs",
            "ic-renderer-tree",
            "ic-renderer-table",
            "ic-renderer-treeble",
            "ic-renderer-keyvalue",
            "ic-renderer-chart"
        ]
    }
);
