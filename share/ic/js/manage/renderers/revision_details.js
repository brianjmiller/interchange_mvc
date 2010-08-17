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
    "ic-manage-renderers-revisiondetails",
    function(Y) {
        var ManageRevisionDetails;

        ManageRevisionDetails = function (config) {
            ManageRevisionDetails.superclass.constructor.apply(this, arguments);
        };

        ManageRevisionDetails.NAME = "ic_manage_renderers_revisiondetails";

        Y.extend(
            ManageRevisionDetails,
            Y.Base,  // should probably extand managewidget to get history...
            {
                _actions: null,

                getContent: function (data, node) {
                    var view_content = this._buildViewTabContent(data);
                    var log_content = this._buildLogTabContent(data);

                    // needs a better prefix
                    this._actions = new Y.IC.ManageDetailActions(
                        {
                            prefix: 'inner',
                            children: [
                                {
                                    label: 'View',
                                    content: view_content
                                },
                                {
                                    label: 'Action Log',
                                    content: log_content
                                },
                                {
                                    label: 'Edit'
                                }
                            ]
                        }
                    );
                    this._actions.render(node);
                    this._buildFormTabContent(data);
                    return node;
                }, 

                _buildViewTabContent: function (data) {
                    // Y.log('tabpanel::_buildContentString');
                    var content = ['<dl>'];
                    Y.each(data, function (v, k) {
                        if (Y.Lang.isString(v) || Y.Lang.isNumber(v)) {
                            content.push('<dt>' + k + ': </dt>' +
                                         '<dd>' + v + '&nbsp;</dd>');
                        }
                        else if (k === 'action_log' || k === 'renderer') {
                            // skip these for now...
                            // they shouldn't even be in the 'content' property
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
                            content.push(this._buildViewTabContent(v));
                        }
                    }, this);
                    content.push('</dl>');
                    return content.join('');
                },

                _buildLogTabContent: function (data) {
                    if (Y.Lang.isValue(data.action_log)) {
                        var content = [];
                        content.push('<div style="text-align: left; font-size: 130%; font-weight: bold;">Log</div>');
                        content.push('<table>');
                        for (i = 0; i < data.action_log.length; i += 1) {
                            row = data.action_log[i];
                            
                            content.push('<tr>');
                            content.push('<td>' + row.label + '</td>');
                            content.push('<td>');
                            if (row.details.length > 0) {
                                for (j = 0; j < row.details.length; j += 1) {
                                    content.push(row.details[j] + "<br />");
                                }
                            }
                            content.push('</td>');
                            content.push('<td>' + row.date_created + '</td>');
                            content.push('<td>' + row.content + '</td>');
                            content.push('</tr>')
                        }
                        content.push('<table>');
                        return content.join('');
                    }
                    else {
                        return 'log';
                    }
                },

                _buildFormTabContent: function (data) {
                    // Y.log('detail::onTabviewRender');
                    // var tab = e.target._items[this._tab_indices['edit']];

                    var fields = [];
                    if (Y.Lang.isValue(data.other_settings)) {
                        var i;
                        for (i = 0; i < data.other_settings.length; i += 1) {
                            row = data.other_settings[i];
                            fields[i] = {
                                name: row.field, 
                                label: row.field, 
                                value: row.value ? row.value.toString() : ''
                            };
                        }
                        fields[i] = {type : 'submit', label : 'Submit'};
                        fields[++i] = {type : 'reset', label : 'Reset'};
                    }

                    var f = new Y.IC.ManageForm({
                        action : '/manage/index', // should be a nice long load...
                        method : 'post',
                        fields : fields
                    });
 
                    f.subscribe('success', function (args) {
                        Y.log('Form submission successful');
                    });
                    f.subscribe('failure', function (args) {
                        Y.log('Form submission failed');
                    });

                    var node = this._actions.getPanelByLabel('Edit');
                    f.render(node);
                }

            }
        );

        Y.namespace("IC");
        Y.IC.ManageRevisionDetails = ManageRevisionDetails;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-detailactions",
            "ic-manage-form"
        ]
    }
);

/******
 * the following is from default.js - before it was trimmed...

                getContent: function (json, node) {
                    this._json = json;
                    var data = json.data || json;

                    Y.log('default::getContent - json');
                    Y.log(json);
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

 *****/
