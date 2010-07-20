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
    "ic-manage-widget-menu",
    function(Y) {
        var ManageMenu;

        ManageMenu = function (config) {
            ManageMenu.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageMenu,
            {
                NAME: "ic_manage_menu",
                ATTRS: {
                }
            }
        );

        Y.extend(
            ManageMenu,
            Y.Widget,
            {
                sections: null,

                DASHBOARD_MENUITEM_TEMPLATE: '\
<li class="yui3-menuitem">\
  <em id="manage_menu_item-dashboard"\
    class="yui3-menuitem-content">Dashboard</em>\
</li>',
                SUBMENU_LABEL_TEMPLATE: '\
<li>\
  <a class="yui3-menu-label">\
    <{menu_item_content_wrapper}>{display_label}<{menu_item_content_wrapper}>\
  </a>',
                SUBMENU_TEMPLATE: '\
<div id="manage_menu-{code}"\
     class="yui3-menu">\
  <div class="yui3-menu-content">\
    <ul>',
                SUBMENU_ITEM_TEMPLATE: '\
<li class="yui3-menuitem">\
  <a id="manage_menu_item-function-list-{code}"\
     class="yui3-menuitem-content">{display_label}</a>\
</li>',
// it would be preferred to use custom properties. ex:
// <a kind="function" sub_kind="list" args="arg1=foo&arg2=bar&arg3=baz">Item Label</a>

                SUBMENU_CLOSE_TEMPLATE: '</ul></div></div></li>',

                // setup a vertical orientation as the default
                orientation_class: '',
                menu_item_content_wrapper: 'span',

                initializer: function (config) {
                    // Y.log("manage menu initializer");

                    if (config.orientation === 'horizontal') {
                        this.orientation_class =  'yui3-menu-horizontal yui3-menubuttonnav';
                        this.menu_item_content_wrapper = 'em';
                    }

                    var menu = this;

                    Y.io(
                        "/manage/widget/menu/config",
                        {
                            // need this to be synchronous so that the render call happens immediately
                            // so that the menu is rendered above the container... if we could break
                            // the render cycle out, possibly into an event callback then this could
                            // become async
                            sync: false,
                            on: {
                                success: function (txnId, response) {
                                    try {
                                        menu_config = Y.JSON.parse(response.responseText);
                                    }
                                    catch (e) {
                                        Y.log("Can't parse JSON: " + e, "error");
                                        return;
                                    }

                                    menu.render(config.render_to);

                                    return;
                                },

                                failure: function (txnId, response) {
                                    Y.log("Failed to get menu options", "error");
                                }
                            }
                        }
                    );
                },

                renderUI: function () {
                    // Y.log('menu renderUI...');
                },

                syncUI: function () {
                    // Y.log('menu syncUI...');

                    this.get("boundingBox").addClass("yui3-menu " + this.orientation_class);
                    this.get("contentBox").addClass("yui3-menu-content");
                    
                    var item_html = Y.substitute(
                        this.DASHBOARD_MENUITEM_TEMPLATE,
                        {
                            menu_item_content_wrapper: this.menu_item_content_wrapper
                        }
                    );

                    var _this = this;
                    Y.each(
                        menu_config["sections"],
                        function (v, i, list) {
                            item_html += Y.substitute(
                                _this.SUBMENU_LABEL_TEMPLATE, 
                                {
                                    menu_item_content_wrapper: _this.menu_item_content_wrapper,
                                    display_label: v["display_label"]
                                }
                            );

                            item_html += Y.substitute(
                                _this.SUBMENU_TEMPLATE,
                                {
                                    code: v["code"]
                                }
                            );
                            Y.each(
                                v["functions"],
                                function (vv, vi, vlist) {
                                    item_html += Y.substitute(
                                        _this.SUBMENU_ITEM_TEMPLATE,
                                        {
                                            code: vv["code"],
                                            display_label: vv["display_label"]
                                        }
                                    );
                                }
                            );
                            item_html += _this.SUBMENU_CLOSE_TEMPLATE;
                        }
                    );

                    this.get("contentBox").setContent("<ul>" + item_html + "</ul>");
                    this.get("boundingBox").plug(Y.Plugin.NodeMenuNav);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageMenu = ManageMenu;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-menu-css", 
            "widget",
            "node-menunav", 
            "io", 
            "json-parse", 
            "substitute"
        ]
    }
);

