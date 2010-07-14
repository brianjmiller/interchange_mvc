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
    "ic-manage-renderers-default",
    function(Y) {
        var ManageDefaultRenderer;

        ManageDefaultRenderer = function (config) {
            ManageDefaultRenderer.superclass.constructor.apply(this, arguments);
        };

        ManageDefaultRenderer.NAME = "ic_manage_renderers_default";

        Y.extend(
            ManageDefaultRenderer,
            Y.Base,
            {
                getContent: function (data, node) {
                    var view_content = this._buildContentString(data);
                    node.setContent(view_content);
                    return node;
                },

                _buildContentString: function (data) {
                    // Y.log('default::_buildContentString');
                    var content = ['<dl>'];
                    Y.each(data, function (v, k) {
                        if (Y.Lang.isString(v) || Y.Lang.isNumber(v)) {
                            content.push('<dt>' + k + ': </dt>' +
                                         '<dd>' + v + '&nbsp;</dd>');
                        }
                        else if (k === 'action_log') {
                            // skip these for now...
                        }
                        else if (Y.Lang.isArray(v) && 
                                 Y.Lang.isObject(v[0]) && 
                                 Y.Lang.isValue(v[0].field)) {
                            Y.each(v, function (o) {
                                content.push('<dt>' + o.field + ': </dt>' + 
                                             '<dd>' + o.value + '&nbsp;</dd>');
                            });
                        }
                        else if (Y.Lang.isObject(v)) {
                            content.push(this._buildContentString(v));
                        }
                    }, this);
                    content.push('</dl>');
                    return content.join('');
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageDefaultRenderer = ManageDefaultRenderer;
    },
    "@VERSION@",
    {
        requires: [
            "base-base"
        ]
    }
);


