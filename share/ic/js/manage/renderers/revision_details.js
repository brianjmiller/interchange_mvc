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
                        else if (k === 'renderer') {
                            // skip these for now...
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

                    var f = new Y.Form({
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
            "gallery-form"
        ]
    }
);









