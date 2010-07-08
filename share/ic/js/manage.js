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


YUI(
    {
        filter: 'raw',
        combine: false,
        insertBefore: 'styleoverrides',
        groups: {
            icjs: {
                combine: false,
                base: "/ic/js/",
                modules: {
                    "ic-manage-widget-dashboard": {
                        path: "manage/widgets/dashboard.js",
                        requires: [
                            "ic-manage-widget-dashboard-css",
                            "ic-manage-widget"
                        ]
                    },
                    "ic-manage-history": {
                        path: "manage/history.js",
                        requires: [
                            "gallery-history-lite",
                            "base-base",
                            "event-custom"
                        ]
                    },
                    "ic-history-manager": {
                        path: "manage/history_manager.js",
                        requires: [
                            "gallery-history-lite"
                        ]
                    },
                    "ic-manage-widget": {
                        path: "manage/widget.js",
                        requires: [
                            "ic-history-manager",
                            "base-base",
                            "widget"
                        ]
                    },
                    "ic-manage-plugin-treeview": {
                        path: "manage/plugins/treeview.js",
                        requires: [
                            "ic-manage-plugin-treeview-css"
                        ]
                    },
                    "ic-manage-plugin-tabpanel": {
                        path: "manage/plugins/tabpanel.js",
                        requires: [
                            "ic-manage-plugin-tabpanel-css",
                            "gallery-widget-io",
                            "widget-stdmod",
                            "ic-manage-renderers-revisiondetails",
                            "ic-manage-plugin-treeview"
                        ]
                    },
                    "ic-manage-renderers-revisiondetails": {
                        path: "manage/renderers/revision_details.js",
                        requires: [
                            "ic-manage-widget-detailactions",
                            "gallery-form"
                        ]
                    },
                    "ic-manage-widget-tabview": {
                        path: "manage/widgets/tabview.js",
                        requires: [
                            "tabview",
                            "ic-history-manager"
                        ]
                    },
                    "ic-manage-widget-detailactions": {
                        path: "manage/widgets/detail_actions.js",
                        requires: [
                            "ic-manage-widget-tabview"
                        ]
                    },
                    "ic-manage-widget-function": {
                        path: "manage/widgets/function.js",
                        requires: [
                            "ic-manage-widget"
                        ]
                    },
                    "ic-manage-widget-function-list": {
                        path: "manage/widgets/functions/list.js",
                        requires: [
                            "ic-manage-widget-function-list-css",
                            "querystring",
                            "ic-manage-widget-function",
                            "datasource",
                            "gallery-datasource-wrapper",
                            // TODO: can we load these later?
                            "yui2-datatable",
                            "yui2-paginator"
                        ],
                        ignore: [
                            "yui2-datasource"
                        ]
                    },
                    "rowexpansion": {
                        path: "manage/widgets/functions/rowexpansion.js",
                        requires: [
                            "yui2-datatable"
                        ]
                    },
                    "ic-manage-widget-function-expandable-list": {
                        path: "manage/widgets/functions/expandable_list.js",
                        requires: [
                            "ic-manage-widget-function-expandable-list-css",
                            "ic-manage-widget-function-list",
                            "widget-parent",
                            "rowexpansion"
                        ]
                    },
                    "ic-manage-widget-function-detail": {
                        path: "manage/widgets/functions/detail.js",
                        requires: [
                            "ic-manage-widget-function-detail-css",
                            "ic-manage-widget-function",
                            "ic-manage-widget-tabview",
                            "ic-manage-plugin-tabpanel"
                        ]
                    },
                    "ic-manage-widget-container": {
                        path: "manage/widgets/container.js",
                        requires: [
                            "querystring",
                            "ic-manage-widget-container-css",
                            "ic-manage-widget-function-list",
                            "ic-manage-widget-function-expandable-list",
                            "ic-manage-widget-function-detail",
                            "ic-manage-widget"
                        ]
                    },
                    "ic-manage-widget-menu": {
                        path: "manage/widgets/menu.js",
                        requires: [ 
                            "ic-manage-widget-menu-css", 
                            "node-menunav", 
                            "io", 
                            "json-parse", 
                            "event", 
                            "node",
                            "substitute"
                        ]
                    },
                    "ic-manage-window": {
                        path: "manage/window.js",
                        requires: [
                            "ic-manage-window-css",
                            "base-base",
                            "ic-manage-widget-container",
                            "ic-manage-widget-menu",
                            "ic-manage-widget-dashboard",
                            "ic-history-manager",
                            "yui2-layout",
                            "yui2-resize"
                        ]
                    }
                }
            },
            iccss: {
                base: "/ic/styles/",
                modules: {
                    "ic-manage-widget-dashboard-css": {
                        path: "manage/widgets/dashboard.css",
                        type: "css"
                    },
                    "ic-manage-widget-function-list-css": {
                        path: "manage/widgets/functions/list.css",
                        type: "css"
                    },
                    "ic-manage-widget-function-expandable-list-css": {
                        path: "manage/widgets/functions/expandable_list.css",
                        type: "css"
                    },
                    "ic-manage-widget-function-detail-css": {
                        path: "manage/widgets/functions/detail.css",
                        type: "css"
                    },
                    "ic-manage-widget-container-css": {
                        path: "manage/widgets/container.css",
                        type: "css"
                    },
                    "ic-manage-widget-menu-css": {
                        path: "manage/widgets/menu.css",
                        type: "css"
                    },
                    "ic-manage-plugin-tabpanel-css": {
                        path: "manage/plugins/tabpanel.css",
                        type: "css"
                    },
                    "ic-manage-plugin-treeview-css": {
                        path: "manage/plugins/treeview.css",
                        type: "css"
                    },
                    "ic-manage-window-css": {
                        path: "manage/window.css",
                        type: "css"
                    }
                }
            },
            yui2css: {
            }
        }
    }
).use(
    "console",
    "ic-manage-window",
    "ic-manage-history",
    function (Y) {

        Y.Node.prototype.ancestors = function (selector) {
            var ancestors = [];
            var ancestor = this.ancestor(selector);
            while (1) {
                if (ancestor) {
                    ancestors.push(ancestor);
                    ancestor = ancestor.ancestor('ul.yui3-treeviewlite>li');
                }
                else {
                    break;
                }
            }
            return Y.all(ancestors);
        };

        Y.Node.prototype.scrollToTop = function (container) {
            var container_top = container.get('region').top;
            var node_top = this.get('region').top;
            var scroll_top = node_top - container_top;
            Y.Node.getDOMNode(container).scrollTop = scroll_top;
        };

        Y.on(
            "domready",
            function () {
                // Y.log("firing dom ready event");
                var console = new Y.Console(
                    {
                        logSource: Y.Global,
                        newestOnTop: 0,
                        height: "98%"
                    }
                );
                console.render();
                console.hide();

                var console_toggle = Y.one("#console_toggle");
                Y.on(
                    "click",
                    function (e, console) {
                        //Y.log("toggle: " + this);
                        //Y.log("value: " + this.get("value"));
                        if (this.get("value") === "1") {
                            //Y.log("hide console: " + console);
                            console.hide();
                            this.set("value", 0);
                            this.set("innerHTML", "show");
                        }
                        else {
                            //Y.log("show console: " + console);
                            console.show();
                            this.set("value", 1);
                            this.set("innerHTML", "hide");
                        }
                    },
                    console_toggle,
                    console_toggle,
                    console
                );

                // both the history and window instances
                //  should be singletons...

                // instantiate a history instance
                var hist = new Y.IC.ManageHistory();

                // Y.log("setting up manage window");
                var mw = new Y.IC.ManageWindow({prefix: '_mw'});

                // hide our loading screen
                Y.on('contentready', function () {
                    Y.one('#application-loading').addClass('hide');
                }, '#manage_menu');
            }
        );
    }
);
