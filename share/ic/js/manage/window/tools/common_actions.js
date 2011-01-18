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
    "ic-manage-window-tools-common_actions",
    function(Y) {
        var Clazz = Y.namespace("IC.ManageTool").CommonActions = Y.Base.create(
            "ic_manage_tools_common_actions",
            Y.IC.ManageTool.Dynamic,
            [],
            {
                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._data_url = "/manage/widget/tools/common_actions/data?_format=json";
                    Y.log(Clazz.NAME + "::initializer - _data_url: " + this._data_url);
                },

                syncUI: function () {
                    Y.log(Clazz.NAME + "::syncUI");

                    Clazz.superclass.syncUI.apply(this, arguments);

                    this.getStdModNode( Y.WidgetStdMod.BODY ).addClass("centered");
                },

                _handleNewData: function (new_data) {
                    //Y.log(Clazz.NAME + "::_handleNewData");

                    this.getStdModNode( Y.WidgetStdMod.BODY ).setContent("");

                    if (Y.Lang.isValue(new_data.buttons) && new_data.buttons.length > 0) {
                        Y.each(
                            new_data.buttons,
                            function (config, i, a) {
                                var button = Y.Node.create('<button>' + config.label + '</button>');
                                button.on(
                                    "click",
                                    function (e) {
                                        e.preventDefault();
                                        this._window.fire(
                                            "contentPaneShowContent",
                                            config.kind,
                                            config.clazz,
                                            config.action,
                                            config.args
                                        );
                                    },
                                    this
                                );
                                this.getStdModNode(Y.WidgetStdMod.BODY).append(button);
                            },
                            this
                        );
                    }
                }
            },
            {
                ATTRS: {
                    update_interval: {
                        value: 60,
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-common_actions-css",
            "ic-manage-window-tools-dynamic"
        ]
    }
);
