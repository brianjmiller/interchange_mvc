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
    "ic-manage-renderers-table",
    function(Y) {
        var ManageTableRenderer;

        ManageTableRenderer = function (config) {
            ManageTableRenderer.superclass.constructor.apply(this, arguments);
        };

        ManageTableRenderer.NAME = "ic_manage_renderers_table";

        Y.extend(
            ManageTableRenderer,
            Y.IC.ManageDefaultRenderer,
            {

// recovering some whitespace...

    _headers: null,

    getContent: function (json, node) {
        // Y.log('default::getContent - json');
        // Y.log(json);

        this._json = json;
        this._headers = json.headers;
        var data = json.data || json;
        var content = Y.Node.create('<table></table>');
        this._buildTable(data, content);
        node.setContent(content);
        return node;
    },

    _buildTable: function (data, content) {
        Y.log('table::_buildTable');
        Y.each(this._headers, function (v) {
            var th = Y.Node.create(
                '<th>' + v + '</th>'
            );
            content.appendChild(th);
        });
        Y.each(data, function (row) {
            var tr = Y.Node.create('<tr></tr>');
            Y.each(row, function (col) {
                var td = Y.Node.create(
                    '<td>' + col + '</td>'
                );
                tr.appendChild(td);
            });
            content.appendChild(tr);
        });
    }

// returning recovered whitespace

            }
        );

        Y.namespace("IC");
        Y.IC.ManageTableRenderer = ManageTableRenderer;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-renderers-default"
        ]
    }
);
