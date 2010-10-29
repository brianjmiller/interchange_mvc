<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <title>IC: Management Area</title>

    <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?<%= $yui_version %>/build/cssreset/reset-min.css&<%= $yui_version %>/build/cssfonts/fonts-min.css&<%= $yui_version %>/build/cssgrids/grids-min.css&<%= $yui_version %>/build/cssbase/base-min.css">

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
    <div id="manage_footer">
        Console: <button id="console_toggle" class="" type="button" value="0">show</button>
    </div>
</div>

<div id="application-loading">
    Loading Site Management...
</div>

<!-- YUI Seed -->
<script type="text/javascript" src="http://yui.yahooapis.com/combo?<%= $yui_version %>/build/yui/yui.js&<%= $yui_version %>/build/loader/loader.js"></script>
<script type="text/javascript" src="/ic/js/manage.js"></script>

</body>
</html>
