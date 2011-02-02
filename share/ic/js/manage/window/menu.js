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
    "ic-manage-window-menu",
    function(Y) {
        var Clazz = Y.namespace("IC").ManageMenu = Y.Base.create(
            "ic_manage_menu",
            Y.Widget,
            [],
            {
                sections: null,

                DASHBOARD_MENUITEM_TEMPLATE: '<li class="yui3-menuitem"><em id="manage_menu_item-remote_dashboard" class="yui3-menuitem-content">Dashboard</em></li>',
                SUBMENU_LABEL_TEMPLATE:      '<li><a class="yui3-menu-label"><{menu_item_content_wrapper}>{display_label}<{menu_item_content_wrapper}></a>',
                SUBMENU_TEMPLATE:            '<div id="manage_menu-{code}" class="yui3-menu"><div class="yui3-menu-content"><ul>',
                SUBMENU_ITEM_TEMPLATE:       '<li class="yui3-menuitem"><a id="manage_menu_item-remote_function-{clazz}-{action}" class="yui3-menuitem-content">{display_label}</a></li>',
                SUBMENU_CLOSE_TEMPLATE:      '</ul></div></div></li>',

                // setup a vertical orientation as the default
                orientation_class:         '',
                menu_item_content_wrapper: 'span',

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    if (config.orientation === 'horizontal') {
                        this.orientation_class         = 'yui3-menu-horizontal yui3-menubuttonnav';
                        this.menu_item_content_wrapper = 'em';
                    }

                    var menu = this;

                    Y.io(
                        // TODO: rename this to window
                        "/manage/widget/menu/config",
                        {
                            on: {
                                success: function (txnId, response) {
                                    try {
                                        menu_config = Y.JSON.parse(response.responseText);
                                    }
                                    catch (e) {
                                        Y.log(Clazz.NAME + "::initializer - io success handler - Can't parse JSON: " + e, "error");
                                        return;
                                    }

                                    menu.render(config.render_to);

                                    return;
                                },

                                failure: function (txnId, response) {
                                    Y.log(Clazz.NAME + "::initializer - io failure handler - Failed to get menu options", "error");
                                }
                            }
                        }
                    );
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");

                    this.get("boundingBox").addClass("yui3-menu " + this.orientation_class);
                    this.get("contentBox").addClass("yui3-menu-content");

                    var item_html = Y.substitute(
                        this.DASHBOARD_MENUITEM_TEMPLATE,
                        {
                            menu_item_content_wrapper: this.menu_item_content_wrapper
                        }
                    );

                    Y.each(
                        menu_config,
                        function (v, i, list) {
                            item_html += this._compileMenuNode(v);
                        },
                        this
                    );

                    this.get("contentBox").setContent("<ul>" + item_html + "</ul>");
                    this.get("boundingBox").plug(
                        Y.Plugin.NodeMenuNav
                    );
                },

                _compileMenuNode: function (node) {
                    //Y.log(Clazz.NAME + "::_compileMenuNode");
                    var return_html;

                    if (node.action) {
                        return_html = Y.substitute(
                            this.SUBMENU_ITEM_TEMPLATE,
                            {
                                clazz:         node.action.baseclass,
                                action:        node.action.subclass,
                                display_label: node.label
                            }
                        );
                    }
                    else {
                        return_html = Y.substitute(
                            this.SUBMENU_LABEL_TEMPLATE, 
                            {
                                menu_item_content_wrapper: this.menu_item_content_wrapper,
                                display_label:             node.label
                            }
                        );
                        if (node.branches) {
                            return_html += Y.substitute(
                                this.SUBMENU_TEMPLATE,
                                {
                                    code: node.label
                                }
                            );

                            Y.each(
                                node.branches,
                                function (v, i, list) {
                                    return_html += this._compileMenuNode(v);
                                },
                                this
                            );

                            return_html += this.SUBMENU_CLOSE_TEMPLATE;
                        }
                    }

                    return return_html;
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
            "ic-manage-window-menu-css",
            "widget",
            "node-menunav",
            "io",
            "json-parse",
            "substitute"
        ]
    }
);
