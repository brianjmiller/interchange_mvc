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
                        content: "Loading..."
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
                            content: 'Loading...'
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
                        this._buildViewTab(data);
                    }
                    else {
                        node.setContent(this._buildContentString(data));
                    }
                    return node;
                },

                _buildContentString: function (data) {
                    // Y.log('default::_buildContentString');
                    var content = ['<dl>'];
                    Y.each(data, function (v, k) {
                        if (Y.Lang.isString(v) || Y.Lang.isNumber(v)) {
                            content.push('<dt>' + k + ': </dt>' +
                                         '<dd field="' + k + '">' + 
                                         v + '&nbsp;</dd>');
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

                _buildViewTab: function (data) {
                    var node = this._actions.getPanel('View');
                    node.setContent('');
                    var content_str = this._buildContentString(data);
                    node.setContent(content_str);
                },

                _buildEditTabForm: function (data) {
                    var tab = this._actions.getTab('Edit');
                    var node = tab.get('panelNode');
                    node.setContent('');

                    if (data.title) {
                        tab.set('label', data.title);
                    }

                    var fields = [];
                    var pk_params = '';
                    Y.each(data.pk_pairs, function (v, k) {
                        pk_params += '&' + k + '=' + v;
                        fields.push({
                            name: k,
                            value: v,
                            type: 'hidden'
                        });
                    });

                    Y.log('data:');
                    Y.log(data);

                    // var hidden = [];
                    Y.each(data.form_fields, function (v) {
                        if (!Y.Lang.isUndefined(v.name)) {
                            fields.push(v);
                        }
                        /*
                        else if (Y.Lang.isValue(v._method)) {
                            hidden.push({name: v._method,
                                         value: v.value,
                                         type: 'hidden'});
                        }
                        */
                    });
                    fields.push({
                        name: '_mode',
                        value: 'store',
                        type: 'hidden'
                    });
                    fields.push({
                        name: '_properties_mode',
                        value: 'edit',
                        type: 'hidden'
                    });

                    // 'hidden' fields should be shown but not editable
                    // fields = fields.concat(hidden);

                    var action = '/manage/function/' +
                        data.func + 
                        '?_mode=store&_properties_mode=edit' +
                        pk_params;
                    fields.push(data.button_field);
                    
                    Y.log('fields:');
                    Y.log(Y.merge(fields));
                    
                    var f = new Y.IC.ManageForm({
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
                    this._addEditableFields(data);
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
                },

                _addEditableFields: function (data) {
                    // Y.log('default::_addEditableFields');
                    var node, key, i, name, value, pk_fields, type, choices, 
                        multiple, udo, field;
                    node = this._actions.getPanel('View');
                    node.all('dd').each(function (v) {
                        key = v.getAttribute('field');
                        if (data.form_fields) {
                            for (var i = 0; i < data.form_fields.length; ++i) {
                                field = data.form_fields[i];
                                name = field.name || null;
                                value = field.value || null;
                                if (name === key) {
                                    pk_fields = [];
                                    Y.each(data.pk_pairs, function (v, k) {
                                        pk_fields.push({
                                            name: k.substr(4),
                                            value: v,
                                            type: 'hidden'
                                        });
                                        pk_fields.push({
                                            name: k,
                                            value: v,
                                            type: 'hidden'
                                        });
                                    });
                                    type = field.type || 'text';
                                    choices = field.choices || null;
                                    multiple = field.multiple || null;
                                    udo = field.useDefaultOption || null;
                                    v.plug(Y.IC.ManageEditable, {
                                        func_code: data.func,
                                        mode: 'store',
                                        properties_mode: 'edit',
                                        pk_fields: pk_fields,
                                        value: value,
                                        multiple: multiple,
                                        useDefaultOption: udo,
                                        choices: choices,
                                        field_name: name,
                                        field_type: type
                                    });
                                    /*
                                      // hard code vals for debugging...
                                    v.plug(Y.IC.ManageEditable, {
                                        func_code: data.func,
                                        mode: 'store',
                                        properties_mode: 'edit',
                                        pk: pk,
                                        pk_fields: pk_fields,
                                        value: value,
                                        // multiple: true,
                                        // useDefaultOption: false,
                                        choices: choices,
                                        field_name: name,
                                        field_type: type
                                    });
                                    */
                                }
                            }
                        }
                    });
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageDefaultRenderer = ManageDefaultRenderer;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "ic-manage-widget-detailactions",
            "ic-manage-form"
        ]
    }
);


