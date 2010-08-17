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
    "ic-manage-renderers-grid",
    function(Y) {
        var ManageGridRenderer;

        ManageGridRenderer = function (config) {
            ManageGridRenderer.superclass.constructor.apply(this, arguments);
        };

        ManageGridRenderer.NAME = "ic_manage_renderers_grid";

        Y.extend(
            ManageGridRenderer,
            Y.IC.ManageDefaultRenderer,
            {

// recovering some whitespace...

    getContent: function (json, node) {
        Y.log('grid::getContent - json');
        Y.log(json);

        this._json = json;
        // look for a type (such as key value)
        this._type = json.type || 'key_value';
        var data = json.data || json;
        var content = Y.Node.create('<div></div>');
        if (this._type === 'key_value') {
            this._buildKeyValueContent(data, content);
        }
        else {
            // add additional types
            Y.log('not a key_value type');
            this._buildKeyValueContent(data, content);
        }
        node.setContent(content);
        return node;
    },

    _buildKeyValueContent: function (data, node) {
        // Y.log('grid::_buildContentString');
        Y.each(data, function (v, k) {
            var content;
            if (k === 'data') {
                content = Y.Node.create('<dl></dl>');
                Y.each(v, function (o) {
                    var dt = Y.Node.create('<dt>' + o.label + ': </dt>');
                    var dd = Y.Node.create('<dd>' + o.value + '&nbsp;</dd>')
                    if (Y.Lang.isObject(o.form)) {
                        dd.plug(Y.IC.ManageEditable, {
                            pk_settings: this.get('pk_settings'),
                            form_data: o.form
                        })
                    }
                    content.appendChild(dt);
                    content.appendChild(dd);
                }, this);
                node.appendChild(content);
            }
            else if (Y.Lang.isObject(v)) {
                this._buildKeyValueContent(v, node);
            }
        }, this);
    }

// returning recovered whitespace

            }, {
                ATTRS: {
                    pk_settings: {
                        value: null
                    }
                }
            }

        );

        Y.namespace("IC");
        Y.IC.ManageGridRenderer = ManageGridRenderer;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-renderers-default",
            "ic-manage-plugin-editable"
        ]
    }
);
