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
    "ic-manage-widget-function-detail",
    function(Y) {
        var ManageFunction;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageFunctionDetail = function (config) {
            ManageFunctionDetail.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageFunctionDetail,
            {
                NAME: "ic_manage_function_detail",
                ATTRS: {
                    code: {
                        value: null
                    },
                    kind: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageFunctionDetail,
            Y.Widget,
            {
                _meta_data: null,

                initializer: function(config) {
                    Y.log("detail initializer: " + this.get("code") + " - " + config.addtl_args, "debug");

                    var url = "/manage/function/" + this.get("code") + "/0?_mode=config&_format=json";
                    url = url + "&" + config.addtl_args;
                    Y.log("Url: " + url, "debug");

                    var return_data = null;
                    Y.io(
                        url,
                        {
                            sync: true,
                            on: {
                                success: function (txnId, response) {
                                    try {
                                        return_data = Y.JSON.parse(response.responseText);
                                    }
                                    catch (e) {
                                        Y.log("Can't parse JSON: " + e, "error");
                                        return;
                                    }

                                    return;
                                },

                                failure: function (txnId, response) {
                                    Y.log("Failed to get function meta data", "error");
                                }
                            }
                        }
                    );

                    this._meta_data = return_data;
                },

                renderUI: function() {
                    var row = null,
                        action_log_tab_index = null,
                        action_log_tab_content = ""
                    ;
                    var contentBox = this.get("contentBox");

                    var data = this._meta_data;

                    contentBox.setContent('<div style="text-align: left; font-size: 110%;">' + data.object_name + '</div>');

                    var tab_config_children = [
                        {
                            label: "Details",
                        }
                    ];

                    tab_config_children[0].content = data.pk_settings[0].field + ": " + data.pk_settings[0].value;

                    if (Y.Lang.isValue(data.other_settings)) {
                        tab_config_children[0].content += "<br /><br />";
                        for (i = 0; i < data.other_settings.length; i += 1) {
                            row = data.other_settings[i];

                            tab_config_children[0].content += row.field + ": " + row.value + "<br />";
                        }
                    }

                    if (Y.Lang.isValue(data.action_log)) {
                        action_log_tab_index = tab_config_children.push(
                            {
                                label: "Log"
                            }
                        );

                        action_log_tab_content += '<div style="text-align: left; font-size: 130%; font-weight: bold;">Log</div>';
                        action_log_tab_content += '<table>';
                        for (i = 0; i < data.action_log.length; i += 1) {
                            row = data.action_log[i];

                            action_log_tab_content += '<tr>'
                            action_log_tab_content += '<td>' + row.label + '</td>';
                            action_log_tab_content += '<td>';
                            if (row.details.length > 0) {
                                for (j = 0; j < row.details.length; j += 1) {
                                    action_log_tab_content += row.details[j] + "<br />";
                                }
                            }
                            action_log_tab_content += '</td>';
                            action_log_tab_content += '<td>' + row.date_created + '</td>';
                            action_log_tab_content += '<td>' + row.content + '</td>';
                            action_log_tab_content += '</tr>'
                        }
                        action_log_tab_content += '<table>';

                        tab_config_children[action_log_tab_index - 1].content = action_log_tab_content;
                    }

                    var tabs = new Y.TabView(
                        {
                            children: tab_config_children
                        }
                    );
                    tabs.render(contentBox);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunctionDetail = ManageFunctionDetail;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
            "tabview"
        ]
    }
);
