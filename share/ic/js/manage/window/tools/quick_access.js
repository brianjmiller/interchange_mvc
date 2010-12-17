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
    "ic-manage-window-tools-quick_access",
    function(Y) {
        var Clazz = Y.namespace("IC.ManageTool").QuickAccess = Y.Base.create(
            "ic_manage_tools_quick_access",
            Y.IC.ManageTool.Dynamic,
            [],
            {
                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._data_url = "/manage/widget/tools/quick_access/data?_format=json";
                    Y.log(Clazz.NAME + "::initializer - _data_url: " + this._data_url);
                },

                _handleNewData: function (new_data) {
                    //Y.log(Clazz.NAME + "::_handleNewData");
                    this.getStdModNode( Y.WidgetStdMod.BODY ).setContent("");

                    if (Y.Lang.isValue(new_data.forms)) {
                        Y.each(
                            new_data.forms,
                            function (form_config, i, a) {
                                var input_node = Y.Node.create('<input type="text" value="" />');
                                Y.on(
                                    "key",
                                    function (e) {
                                        Y.log(Clazz.NAME + "::renderUI - return key press in input node: " + e.type + ": " + e.keyCode);
                                        Y.log(Clazz.NAME + "::renderUI - this: " + this);
                                        Y.log(Clazz.NAME + "::renderUI - input_node: " + input_node);
                                        Y.log(Clazz.NAME + "::renderUI - input_node value: " + input_node.get("value"));

                                        e.halt();

                                        var value = input_node.get("value");
                                        if (Y.Lang.isValue(value) && value !== "") {
                                            var addtl_args = {};
                                            addtl_args[form_config.event_args.value_key] = value;

                                            this._window.fire(
                                                form_config.event,
                                                form_config.event_args.kind,
                                                form_config.event_args.clazz,
                                                form_config.event_args.action,
                                                addtl_args
                                            );
                                        }
                                    },
                                    input_node,
                                    'down:13',
                                    this
                                );

                                this.getStdModNode( Y.WidgetStdMod.BODY ).append(form_config.label);
                                this.getStdModNode( Y.WidgetStdMod.BODY ).append(input_node);
                            },
                            this
                        );
                    }
                    else {
                        this.getStdModNode( Y.WidgetStdMod.BODY ).setContent("Nothing configured.");
                    }
                }
            },
            {
                ATTRS: {}
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-quick_access-css",
            "ic-manage-window-tools-dynamic",
        ]
    }
);
