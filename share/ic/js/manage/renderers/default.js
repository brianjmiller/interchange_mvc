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
                _actions: null,
                _json: null,

                getContent: function (json, node) {
                    this._json = json;
                    var tabs = [];
                    var data = json.data || json;
                    tabs.push({
                        label: 'View',
                        content: this._buildContentString(data)
                    });

                    // Y.log('default::getContent - json');
                    // Y.log(json);
                    // if there is a forms.edit, add an edit tab
                    if (json.forms && json.forms.edit) {
                        var form_url = '/manage/function/' +
                            json.forms.edit.func + 
                            '?_mode=config&_properties_mode=edit' +
                            json.forms.edit.pk;
                        Y.io(form_url, {
                            sync: false,
                            on: {
                                success: Y.bind(this._parseJSONForm, this),
                                failure: function (txn_id, response) {
                                    Y.log('Failed to get form data.', 'error');
                                }
                            }
                        });
                        tabs.push({
                            label: 'Edit',
                            content: 'Loading'
                        });
                    }

                    var num_tabs = Y.Object.size(tabs);
                    if (tabs.length > 1) {
                        // build an inner tab set (aka Detail Actions)
                        this._actions = new Y.IC.ManageDetailActions(
                            {
                                prefix: 'inner',
                                children: tabs
                            }
                        );
                        this._actions.render(node);
                    }
                    else {
                        var tab = tabs.pop();
                        if (tab.content) {
                            node.setContent(tab.content);
                        }
                        else {
                            node.setContent('[empty]');
                        }
                    }
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
                        else if (k === 'action_log' || k === 'renderer') {
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
                },

                _buildEditTabForm: function (data) {
                    var tab = this._actions.getTab('Edit');
                    var node = tab.get('panelNode');
                    node.setContent('');

                    if (data.title) {
                        tab.set('label', data.title);
                    }

                    var pk_params = '';
                    Y.each(data.pk_pairs, function (v, k) {
                        pk_params += '&' + k + '=' + v;
                    });

                    // for now, remove any fields without a name
                    var fields = [];
                    Y.each(data.form_fields, function (v, i, o) {
                        if (!Y.Lang.isUndefined(v.name)) {
                            fields.push(v);
                        }
                    });

                    var action = '/manage/function/' +
                        data.func + 
                        '?_mode=store&_properties_mode=edit' +
                        pk_params;
                    fields.push(data.button_field);
                    var f = new Y.Form({
                        action: action,
                        method: 'post',
                        fields: fields,
                        skipValidationBeforeSubmit: true
                    });

                    f.subscribe('success', function (args) {
                        Y.log('Form submission successful');
                    });
                    f.subscribe('failure', function (args) {
                        Y.log('Form submission failed');
                    });
                    
                    f.render(node);
                },

                _parseJSONForm: function (txn_id, response) {
                    var data;
                    try {
                        data = Y.JSON.parse(response.responseText);
                    }
                    catch (err) {
                        data = "Error parsing the JSON form data: " + err;
                    }
                    this._buildEditTabForm(data);
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


