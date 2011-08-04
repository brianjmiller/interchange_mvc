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
    "ic-manage-window-tools",
    function(Y) {
        var Clazz = Y.namespace("IC").ManageTools = Y.Base.create(
            "ic_manage_tools",
            Y.Widget,
            [],
            {
                _accordion: null,

                initializer: function (config) {
                    //Y.log(Clazz.NAME + "::initializer");
                },

                destructor: function () {
                    //Y.log(Clazz.NAME + "::destructor");
                    this._accordion.destroy();
                    this._accordion = null;
                },

                renderUI: function () {
                    //Y.log(Clazz.NAME + "::renderUI");

                    var content_height = this._getContentHeight();
                    var empty_node     = Y.Node.create('<span />');

                    this._accordion = new Y.Accordion (
                        {
                            render:                 this.get("contentBox"),
                            useAnimation:           true,
                            collapseOthersOnExpand: true
                        }
                    );

                    var acc_common_config = {
                        icon:              empty_node,
                        iconAlwaysVisible: empty_node,
                        contentHeight:     {
                            method: "fixed",
                            height: content_height
                        }
                    };

                    var items = [
                        {
                            label:                 "Common Actions",
                            id:                    "ic-manage-tools-common_actions",
                            content_module:        Y.IC.ManageTool.CommonActions,
                            content_module_config: this.get("common_actions"),
                            expanded:              true
                        },
                        {
                            label:                 "Quick Access",
                            id:                    "ic-manage-tools-quick_access",
                            content_module:        Y.IC.ManageTool.QuickAccess,
                            content_module_config: this.get("quick_access")
                        },
                        {
                            label:          "Your Links",
                            id:             "ic-manage-tools-your_links",
                            content_module: Y.IC.ManageTool.YourLinks
                        }
                    ];

                    Y.each(
                        items,
                        function (config, i, a) {
                            Y.mix(config, acc_common_config);
                            //Y.log(Clazz.NAME + "::renderUI - add accordion item: " + Y.dump(config));

                            // TODO: would this be better off if we just subclassed Y.AccordionItem?
                            var content_module = config.content_module;
                            delete config.content_module;
                            //Y.log(Clazz.NAME + "::renderUI - content_module: " + content_module);

                            var content_module_config = config.content_module_config;
                            delete config.content_module_config;

                            var acc_item = new Y.AccordionItem (config);
                            //Y.log(Clazz.NAME + "::renderUI - acc_item: " + acc_item);

                            this._accordion.addItem(acc_item);
                            //Y.log(Clazz.NAME + "::renderUI - item added");

                            // TODO: this means we need to listen for resize events on the accordion item
                            //Y.log(Clazz.NAME + "::renderUI - acc_item render to: " + acc_item.getStdModNode(Y.WidgetStdMod.BODY));
                            content_module_config = content_module_config || {};
                            Y.mix(
                                content_module_config,
                                {
                                    render: acc_item.getStdModNode(Y.WidgetStdMod.BODY),
                                    window: this.get("window"),
                                    height: content_height
                                }
                            );
                            var content = new content_module.prototype.constructor (content_module_config);
                        },
                        this
                    );
                },

                bindUI: function () {
                    //Y.log(Clazz.NAME + "manage_tools::bindUI");
                    this.get('layout').subscribe(
                        'resize', 
                        Y.bind(this._resizeAccItems, this)
                    );
                },

                _resizeAccItems: function (e) {
                    //Y.log(Clazz.NAME + "::_resizeAccItems");
                    var new_height = this._getContentHeight();

                    Y.each(
                        this._accordion.get("items"),
                        function (v) {
                            v.set(
                                "contentHeight",
                                {
                                    method: "fixed", 
                                    height: new_height
                                }
                            );
                            if (v.get("expanded")) {
                                var body = v.getStdModNode(Y.WidgetStdMod.BODY);
                                body.setStyle("height", new_height);
                            }
                            else {
                                this._accordion._collapseItem(v);
                            }
                        },
                        this
                    );
                },

                _getContentHeight: function () {
                    //Y.log(Clazz.NAME + "::_getContentHeight");
                    var unit          = this.get("layout_unit");
                    var unit_height   = unit.getSizes().body.h;
                    var num_items     = 3;
                    var header_height = 24;
                    var height        = unit_height - (header_height * 3);

                    if (height < 40) height = 40;

                    return height;
                }
            },
            {
                ATTRS: {
                    // the window I'm in
                    window: {
                        value: null
                    },
                    // the layout manager i'm a child of
                    layout: {
                        value: null
                    },
                    // the layout_unit i'm inside
                    layout_unit: {
                        value: null
                    },
                    common_actions: {
                        value: null
                    },
                    quick_access: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-css", 
            "anim",
            "widget",
            "gallery-accordion-css",
            "gallery-accordion",
            "ic-manage-window-tools-common_actions",
            "ic-manage-window-tools-quick_access",
            "ic-manage-window-tools-your_links"
        ]
    }
);
