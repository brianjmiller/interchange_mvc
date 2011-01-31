<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <title>IC: Management Area</title>
    <style>
        .hide-while-loading {
            display: none;
        }
    </style>

    <link rel="stylesheet" type="text/css" href="/combo?ic/vendor/yui3/build/cssreset/reset-min.css&ic/vendor/yui3/build/cssfonts/fonts-min.css&ic/vendor/yui3/build/cssgrids/grids-min.css&ic/vendor/yui3/build/cssbase/base-min.css">

    <style id="styleoverrides">
        /* ideally these would go in a CSS module but I couldn't get it loaded after the ones provided by the core */
        .yui-skin-sam .yui-dt table {
            font-family: inherit;
        }
        .yui-skin-sam .yui-dt-liner {
            white-space:    nowrap;
            padding-top:    1px;
            padding-bottom: 1px;
            line-height:    1.15;
        }
    </style>

    <link rel="stylesheet" type="text/css" href="/combo?ic/styles/base.css&ic/styles/manage.css" />
</head>

<body class="yui-skin-sam yui3-skin-sam">

<div id="ic-manage-window" class="hide-while-loading">
    <div id="manage_header">
        <span>Management Area</span>
    </div>
    <div id="manage_window_content_pane"></div>
    <div id="manage_left_layout">
        <div id="manage_tools_pane"></div>
        <div id="manage_menu_pane"></div>
    </div>
</div>

<div id="application-loading">
    Loading Site Management...
</div>

<%
    # YUI Config 

    # This is a global used by YUI to configure the sandbox instance that wraps
    # the manage application. Pulling this out and storing it in the view means
    # we can adjust it through the controllers context like any other view.
%>
<script type="text/javascript">
    YUI_config = {
        filter:       "raw",
        comboBase:    "/combo?",
        root:         "ic/vendor/yui3/build/",
        combine:      true,
        insertBefore: "styleoverrides",
        groups:       {
            // set up for locally served gallery
            gallery: {
                combine:   true,
                base:      "/ic/vendor/yui3-gallery/build/",
                root:      "ic/vendor/yui3-gallery/build/",
                comboBase: "/combo?",
                update:    function(tag) {
                    //var root = "/ic/vendor/yui3-gallery/";
                    //groups.gallery.base = root;
                    //groups.gallery.root = root;
                },
                patterns: {
                    "gallery-":    {},
                    "gallerycss-": { type: "css" }
                }
            },
            //
            // Don't know why this is needed but it was confirmed as of 2010/08/23 with 3.2.0pr1
            // and caused an odd error with Y.Lang when not included
            //
            gallerycss: {
                combine:   true,
                comboBase: "/combo?",
                root:      "ic/vendor/yui3-gallery/build/",
                modules:   {
                    "gallery-accordion-css": {
                        path: "gallery-accordion/assets/skins/sam/gallery-accordion.css",
                        type: "css"
                    },
                    "gallery-treeviewlite-core-css": {
                        path: "gallery-treeviewlite/assets/gallery-treeviewlite-core.css",
                        type: "css"
                    },
                    "gallery-treeviewlite-skin-css": {
                        path: "gallery-treeviewlite/assets/skins/sam/gallery-treeviewlite-skin.css",
                        type: "css"
                    }
                }
            },
            // TODO: switch to updated gallery version that includes
            //       apipkin's Xarno Calendar and use it instead
            localjs: {
                combine:     false,
                //comboBase:   "/combo?",
                //root:        "ic/js/static/",
                base:        "/ic/js/static/",
                charset:     "utf-8",
                modules:     {
                    // default skin
                    "calendar-skin":{
                        path: "skin.css",
                        type: "css"
                    },
                    "gallery-calendar": {
                        path: "gallery-calendar.js",
                        requires: [
                            "calendar-skin",
                            "widget",
                            "node"
                        ]
                    }
                } 
            },
            // set up for locally served 2in3
            yui2: {
                base:      "/ic/vendor/yui-2in3/dist/2.8.2/build/",
                combine:   true,
                comboBase: "/combo?",
                root:      "ic/vendor/yui-2in3/dist/2.8.2/build/",
                patterns:  {
                    "yui2-": {
                        configFn: function (me) {
                            if(/-skin|reset|fonts|grids|base/.test(me.name)) {
                                me.type = "css";
                                me.path = me.path.replace(/\.js/, ".css");
                                me.path = me.path.replace(/\/yui2-skin/, "/assets/skins/sam/yui2-skin");
                            }
                        }
                    }
                }
            },
            icjs: {
                combine:   true,
                comboBase: "/combo?",
                root:      "ic/js/",
                base:      "/ic/js/",
                modules:   {
                    //
                    // our top level application "controller", it sets up the 
                    // outer most layout and controls the various pieces (panes)
                    //
                    "ic-manage-window": {
                        path: "manage/window.js",
                        requires: [
                            "ic-manage-window-css",
                            "base-base",
                            "yui2-layout",
                            "yui2-resize",
                            "ic-manage-window-menu",
                            "ic-manage-window-tools",
                            "ic-manage-window-content",

                            // our custom ones which we can be reasonably sure we'll use
                            <% if (defined $custom_js) { %>
                                <%= join ', ', map { qq{"$_->{name}"} } @{ $custom_js->{modules} } %>,
                            <% } %>

                            // for debugging
                            "dump"
                        ]
                    },

                    //
                    // set of widgets constructed by window and loaded into
                    // its layout units representing the top level of the 
                    // application interface (the panes)
                    //
                    "ic-manage-window-menu": {
                        path: "manage/window/menu.js",
                        requires: [ 
                            "ic-manage-window-menu-css", 
                            "widget",
                            "node-menunav", 
                            "io", 
                            "json-parse", 
                            "substitute"
                        ]
                    },
                    "ic-manage-window-tools": {
                        path: "manage/window/tools.js",
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
                    },
                    "ic-manage-window-content": {
                        path: "manage/window/content.js",
                        requires: [ 
                            "ic-manage-window-content-css", 
                            "cache",
                            "widget",
                            "widget-parent",
                            "ic-manage-window-content-remote",
                            "ic-manage-window-content-remote-dashboard",
                            "ic-manage-window-content-remote-function",
                            "ic-manage-window-content-remote-record"
                        ]
                    },

                    //
                    // widgets to be stuffed into the tools pane
                    //
                    "ic-manage-window-tools-base": {
                        path: "manage/window/tools/base.js",
                        requires: [ 
                            "ic-manage-window-tools-base-css",
                            "widget"
                        ]
                    },
                    "ic-manage-window-tools-dynamic": {
                        path: "manage/window/tools/dynamic.js",
                        requires: [ 
                            "ic-manage-window-tools-dynamic-css",
                            "widget-stdmod"
                        ]
                    },
                    "ic-manage-window-tools-common_actions": {
                        path: "manage/window/tools/common_actions.js",
                        requires: [ 
                            "ic-manage-window-tools-common_actions-css",
                            "ic-manage-window-tools-dynamic"
                        ]
                    },
                    "ic-manage-window-tools-quick_access": {
                        path: "manage/window/tools/quick_access.js",
                        requires: [ 
                            "ic-manage-window-tools-quick_access-css",
                            "ic-manage-window-tools-base"
                        ]
                    },
                    "ic-manage-window-tools-your_links": {
                        path: "manage/window/tools/your_links.js",
                        requires: [ 
                            "ic-manage-window-tools-your_links-css",
                            "ic-manage-window-tools-base"
                        ]
                    },

                    //
                    // kinds of content widgets that will load their info into the layouts
                    // provided by the content pane
                    //
                    "ic-manage-window-content-base": {
                        path: "manage/window/content/base.js",
                        requires: [ 
                            "widget",
                            "widget-child",
                            "ic-renderer",

                            // the provided set of renderers
                            //
                            // we can't know which ones will be needed by the
                            // functions until we have their data, so go ahead
                            // and include them all here, should figure out if
                            // there is a way we could dynamically load them
                            // on requirement, though that would likely mean
                            // additional requests, at least after the app has
                            // loaded
                            //
                            "ic-renderer-basic",
                            "ic-renderer-tile",
                            "ic-renderer-panel",
                            "ic-renderer-grid",
                            "ic-renderer-form",
                            "ic-renderer-form_wrapper",
                            "ic-renderer-tabs",
                            "ic-renderer-tree",
                            "ic-renderer-table",
                            "ic-renderer-data_table",
                            "ic-renderer-v2_data_table",
                            "ic-renderer-treeble",
                            "ic-renderer-keyvalue",
                            "ic-renderer-chart",
                            "ic-renderer-panel_loader",
                            "ic-renderer-record_set",
                        ]
                    },
                    "ic-manage-window-content-remote": {
                        path:     "manage/window/content/remote.js",
                        requires: [ 
                            //"ic-manage-window-content-remote-css",
                            "ic-manage-window-content-base",
                            "ic-renderer"
                        ]
                    },
                    "ic-manage-window-content-remote-dashboard": {
                        path:     "manage/window/content/remote/dashboard.js",
                        requires: [ 
                            "ic-manage-window-content-remote-dashboard-css",
                            "ic-manage-window-content-remote"
                        ]
                    },
                    "ic-manage-window-content-remote-function": {
                        path:     "manage/window/content/remote/function.js",
                        requires: [ 
                            "ic-manage-window-content-remote-function-css",
                            "ic-manage-window-content-remote"
                        ]
                    },
                    "ic-manage-window-content-remote-record": {
                        path:     "manage/window/content/remote/record.js",
                        requires: [ 
                            "ic-manage-window-content-remote-record-css",
                            "ic-manage-window-content-remote",
                            "querystring"
                        ]
                    },

                    // plugins to add to various instances
                    "ic-plugin-ignorable": {
                        path: "plugin/ignorable.js",
                        requires: [
                            "ic-plugin-ignorable-css",
                            "plugin"
                        ]
                    },
                    "ic-plugin-editable": {
                        path: "plugin/editable.js",
                        requires: [
                            "ic-plugin-editable-css",
                            "plugin",
                            "json-parse",
                            "ic-form"
                        ]
                    },
                    "ic-plugin-editable-in_place": {
                        path: "plugin/editable/in_place.js",
                        requires: [
                            "ic-plugin-editable"
                        ]
                    },
                    "ic-plugin-tablefilter": {
                        path: "plugin/tablefilter.js",
                        requires: [
                            "ic-plugin-tablefilter-css",
                            "plugin",
                            "event-key"
                        ]
                    },

                    //
                    // this is a wrapper class for now, it wraps 
                    // (unsurprisingly) gallery-form, it provides
                    // implementation to set form control type
                    // to our customized fields where necessary,
                    // a custom reset action, and makes the form
                    // pluggable
                    //
                    "ic-form": {
                        path: "form.js",
                        requires: [
                            "pluginhost",
                            "gallery-form",
                            "ic-formfield"
                        ]
                    },

                    // helper class used to load custom form fields
                    "ic-formfield": {
                        path: "form_field.js",
                        requires: [
                            "ic-formfield-calendar",
                            "ic-formfield-calendar_with_time",
                            "ic-formfield-radio"
                        ]
                    },

                    // custom form fields
                    "ic-formfield-calendar": {
                        path: "form_field/calendar.js",
                        requires: [
                            "gallery-form",
                            "gallery-calendar"
                        ]
                    },
                    "ic-formfield-calendar_with_time": {
                        path: "form_field/calendar_with_time.js",
                        requires: [
                            "ic-formfield-calendar"
                        ]
                    },
                    "ic-formfield-radio": {
                        path: "form_field/radio.js",
                        requires: [
                            "gallery-form"
                        ]
                    },

                    // helper class used to request a kind of renderer
                    "ic-renderer": {
                        path: "renderer.js",
                        requires: [
                            "ic-renderer-css"
                        ]
                    },

                    // renderers
                    "ic-renderer-base": {
                        path: "renderer/base.js",
                        requires: [
                            "ic-renderer-base-css",
                            "widget"
                        ]
                    },
                    "ic-renderer-basic": {
                        path: "renderer/basic.js",
                        requires: [
                            "ic-renderer-basic-css",
                            "ic-renderer-base"
                        ]
                    },
                    "ic-renderer-tile": {
                        path: "renderer/tile.js",
                        requires: [
                            "ic-renderer-tile-css",
                            "ic-renderer-base",
                            "cache"
                        ]
                    },
                    "ic-renderer-panel": {
                        path: "renderer/panel.js",
                        requires: [
                            "ic-renderer-panel-css",
                            "ic-renderer-base",
                            "cache"
                        ]
                    },
                    "ic-renderer-grid": {
                        path: "renderer/grid.js",
                        requires: [
                            "ic-renderer-grid-css",
                            "ic-renderer-base",
                            "ic-plugin-ignorable"
                        ]
                    },
                    "ic-renderer-form": {
                        path: "renderer/form.js",
                        requires: [
                            "ic-renderer-form-css",
                            "ic-renderer-base"
                        ]
                    },
                    "ic-renderer-form_wrapper": {
                        path: "renderer/form_wrapper.js",
                        requires: [
                            "ic-renderer-form_wrapper-css",
                            "ic-renderer-base",
                            "ic-form"
                        ]
                    },
                    "ic-renderer-tabs": {
                        path: "renderer/tabs.js",
                        requires: [
                            "ic-renderer-tabs-css",
                            "ic-renderer-base",
                            "tabview"
                        ]
                    },
                    "ic-renderer-tree": {
                        path: "renderer/tree.js",
                        requires: [
                            "ic-renderer-tree-css",
                            "ic-renderer-base",
                            "gallery-treeviewlite",
                            "gallery-treeviewlite-core-css",
                            "gallery-treeviewlite-skin-css"
                        ]
                    },
                    "ic-renderer-table": {
                        path: "renderer/table.js",
                        requires: [
                            "ic-renderer-table-css",
                            "ic-renderer-base"
                        ]
                    },
                    "ic-renderer-data_table": {
                        path: "renderer/data_table.js",
                        requires: [
                            "ic-renderer-data_table-css",
                            "ic-renderer-base",
                            "datatable"
                        ]
                    },
                    "ic-renderer-v2_data_table": {
                        path: "renderer/v2_data_table.js",
                        requires: [
                            "ic-renderer-v2_data_table-css",
                            "ic-renderer-base",
                            "datasource",
                            "overlay",
                            "gallery-datasource-wrapper",
                            "yui2-paginator",
                            "yui2-datatable",
                            "yui2-dragdrop",
                            "querystring",
                            "ic-plugin-tablefilter"
                        ]
                    },
                    "ic-renderer-treeble": {
                        path: "renderer/treeble.js",
                        requires: [
                            "ic-renderer-treeble-css",
                            "ic-renderer-base",
                            "gallery-treeble",
                            "gallery-paginator",
                            "event-valuechange"
                        ]
                    },
                    "ic-renderer-keyvalue": {
                        path: "renderer/keyvalue.js",
                        requires: [
                            "ic-renderer-keyvalue-css",
                            "ic-renderer-base",
                            "ic-plugin-editable-in_place"
                        ]
                    },
                    "ic-renderer-chart": {
                        path: "renderer/chart.js",
                        requires: [
                            "ic-renderer-chart-css",
                            "ic-renderer-base",
                            "charts"
                        ]
                    },
                    "ic-renderer-panel_loader": {
                        path: "renderer/panel_loader.js",
                        requires: [
                            "ic-renderer-panel_loader-css",
                            "ic-renderer-base",
                            "ic-renderer-panel"
                        ]
                    },
                    "ic-renderer-record_set": {
                        path: "renderer/record_set.js",
                        requires: [
                            "ic-renderer-record_set-css",
                            "ic-renderer-base",
                            "cache"
                        ]
                    },

                    "ic-autocomplete": {
                        path: "autocomplete.js",
                        requires: [
                            "autocomplete-base"
                        ]
                    },

                    // utility functions
                    "ic-util": {
                        path: "util.js"
                    }
                }
            },
            iccss: {
                combine:   true,
                comboBase: "/combo?",
                root:      "ic/styles/",
                base:      "/ic/styles/",
                modules: {
                    "ic-plugin-ignorable-css": {
                        path: "plugin/ignorable.css",
                        type: "css"
                    },
                    "ic-plugin-editable-css": {
                        path: "plugin/editable.css",
                        type: "css"
                    },
                    "ic-plugin-tablefilter-css": {
                        path: "plugin/tablefilter.css",
                        type: "css"
                    },

                    "ic-renderer-css": {
                        path: "renderer.css",
                        type: "css"
                    },
                    "ic-renderer-base-css": {
                        path: "renderer/base.css",
                        type: "css"
                    },
                    "ic-renderer-basic-css": {
                        path: "renderer/basic.css",
                        type: "css"
                    },
                    "ic-renderer-tile-css": {
                        path: "renderer/tile.css",
                        type: "css"
                    },
                    "ic-renderer-panel-css": {
                        path: "renderer/panel.css",
                        type: "css"
                    },
                    "ic-renderer-grid-css": {
                        path: "renderer/grid.css",
                        type: "css"
                    },
                    "ic-renderer-form-css": {
                        path: "renderer/form.css",
                        type: "css"
                    },
                    "ic-renderer-form_wrapper-css": {
                        path: "renderer/form_wrapper.css",
                        type: "css"
                    },
                    "ic-renderer-tabs-css": {
                        path: "renderer/tabs.css",
                        type: "css"
                    },
                    "ic-renderer-tree-css": {
                        path: "renderer/tree.css",
                        type: "css"
                    },
                    "ic-renderer-table-css": {
                        path: "renderer/table.css",
                        type: "css"
                    },
                    "ic-renderer-data_table-css": {
                        path: "renderer/data_table.css",
                        type: "css"
                    },
                    "ic-renderer-v2_data_table-css": {
                        path: "renderer/v2_data_table.css",
                        type: "css"
                    },
                    "ic-renderer-treeble-css": {
                        path: "renderer/treeble.css",
                        type: "css"
                    },
                    "ic-renderer-keyvalue-css": {
                        path: "renderer/keyvalue.css",
                        type: "css"
                    },
                    "ic-renderer-chart-css": {
                        path: "renderer/chart.css",
                        type: "css"
                    },
                    "ic-renderer-panel_loader-css": {
                        path: "renderer/panel_loader.css",
                        type: "css"
                    },
                    "ic-renderer-record_set-css": {
                        path: "renderer/record_set.css",
                        type: "css"
                    },
                    "ic-manage-window-css": {
                        path: "manage/window.css",
                        type: "css"
                    },
                    "ic-manage-window-menu-css": {
                        path: "manage/window/menu.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-css": {
                        path: "manage/window/tools.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-base-css": {
                        path: "manage/window/tools/base.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-dynamic-css": {
                        path: "manage/window/tools/dynamic.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-common_actions-css": {
                        path: "manage/window/tools/common_actions.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-quick_access-css": {
                        path: "manage/window/tools/quick_access.css",
                        type: "css"
                    },
                    "ic-manage-window-tools-your_links-css": {
                        path: "manage/window/tools/your_links.css",
                        type: "css"
                    },
                    "ic-manage-window-content-css": {
                        path: "manage/window/content.css",
                        type: "css"
                    },

                    "ic-manage-window-content-remote-dashboard-css": {
                        path: "manage/window/content/remote/dashboard.css",
                        type: "css"
                    },
                    "ic-manage-window-content-remote-function-css": {
                        path: "manage/window/content/remote/function.css",
                        type: "css"
                    },
                    "ic-manage-window-content-remote-record-css": {
                        path: "manage/window/content/remote/record.css",
                        type: "css"
                    },

                    "ic-manage-window-content-dashboard-css": {
                        path: "manage/window/content/dashboard.css",
                        type: "css"
                    },
                    "ic-manage-window-content-layout-base-css": {
                        path: "manage/window/content/layout/base.css",
                        type: "css"
                    },
                    "ic-manage-window-content-layout-full-css": {
                        path: "manage/window/content/layout/full.css",
                        type: "css"
                    },
                    "ic-manage-window-content-layout-h_divided-css": {
                        path: "manage/window/content/layout/h_divided.css",
                        type: "css"
                    },
                    "ic-manage-window-content-function-action-list-css": {
                        path: "manage/window/content/function/action/list.css",
                        type: "css"
                    },
                    "ic-manage-window-content-function-action-list-table-css": {
                        path: "manage/window/content/function/action/list/table.css",
                        type: "css"
                    },
                    "ic-manage-window-content-function-action-list-record-css": {
                        path: "manage/window/content/function/action/list/record.css",
                        type: "css"
                    }
                }
            }
            <% if (defined $custom_js) { %>
                ,customjs: {
                    combine:   true,
                    comboBase: "/combo?",
                    root:      "controlled/js/",
                    base:      "/controlled/js/",
                    modules:   {
                        <%
                            my $index = 0;
                            for my $module_config (@{ $custom_js->{modules} }) {
                        %>
                            <%= $index ? ',' : ''; %>
                            "<%= $module_config->{name} %>": {
                                path: "<%= $module_config->{path} %>"
                                <% if (defined $module_config->{requires}) { %>
                                    ,requires: [
                                        <%= join ", ", map { qq{ "$_" } } @{ $module_config->{requires} } %>
                                    ]
                                <% } %>
                            }
                            <% $index++; %>
                        <% } %>
                    },
                }
            <% } %>
            <% if (defined $custom_css) { %>
                ,customcss: {
                    combine:   true,
                    comboBase: "/combo?",
                    root:      "controlled/styles/",
                    base:      "/controlled/styles/",
                    modules:   {
                        <%
                            my $index = 0;
                            for my $module_config (@{ $custom_css->{modules} }) {
                        %>
                            <%= $index ? ',' : ''; %>
                            "<%= $module_config->{name} %>": {
                                path: "<%= $module_config->{path} %>",
                                type: "css"
                            }
                            <% $index++; %>
                        <% } %>
                    },
                }
            <% } %>
        }
    };
</script>

<!-- YUI Seed, Loader, and our primary source -->
<script type="text/javascript" src="/combo?ic/vendor/yui3/build/yui/yui.js&ic/vendor/yui3/build/loader/loader.js&ic/js/manage.js"></script>

</body>
</html>
