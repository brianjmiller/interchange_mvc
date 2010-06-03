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

                initializer: function (config) {
                    Y.log("manage menu initializer");
                    this.get("boundingBox").addClass("yui3-menu yui3-menu-horizontal yui3-menubuttonnav");
                    this.get("contentBox").addClass("yui3-menu-content");

                    var menu = this;

                    Y.io(
                        "/manage/widget/menu/config",
                        {
                            // need this to be synchronous so that the render call happens immediately
                            // so that the menu is rendered above the container... if we could break
                            // the render cycle out, possibly into an event callback then this could
                            // become async
                            sync: true,
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
                    // Move all of this content to the sync UI?

                    // make this a constant or a Markout thing
                    var item_html = '<li class="yui3-menuitem"><em id="manage_menu_item-dashboard" class="yui3-menuitem-content">Dashboard</em></li>';

                    Y.each(
                        menu_config["sections"],
                        function (v, i, list) {
                            item_html += '<li><a class="yui3-menu-label"><em>' + v["display_label"] + '</em></a>';

                            item_html += '<div id="manage_menu-' + v["code"] + '" class="yui3-menu"><div class="yui3-menu-content"><ul>';
                            Y.each(
                                v["functions"],
                                function (vv, vi, vlist) {
                                    item_html += '<li class="yui3-menuitem"><a id="manage_menu_item-function-' + vv["code"] + '" class="yui3-menuitem-content">' + vv["display_label"] + '</a></li>';
                                }
                            );
                            item_html += '</ul></div></div>';

                            item_html += '</li>';
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
            "widget",
        ]
    }
);

