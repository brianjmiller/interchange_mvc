<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <title>IC: Management Area</title>

    <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?<%= $yui_version %>/build/cssreset/reset-min.css&<%= $yui_version %>/build/cssfonts/fonts-min.css&<%= $yui_version %>/build/cssgrids/grids-min.css&<%= $yui_version %>/build/cssbase/base-min.css">

    <style id="styleoverrides">
        .yui-skin-sam .yui-dt table {
            font-family: inherit;
        }
    </style>

    <link rel="stylesheet" type="text/css" href="/ic/styles/base.css" />
    <link rel="stylesheet" type="text/css" href="/ic/styles/manage.css" />
</head>

<body class="yui-skin-sam yui3-skin-sam">

<div id="ic-manage-app-container" class="hide-while-loading">
    <div id="manage_header">
        <span>Management Area</span>
    </div>
    <div id="manage_quick"></div>
    <div id="manage_menu"></div>
    <div id="manage_datatable"></div>
    <div id="manage_detail"></div>
    <div id="manage_dashboard"></div>
    <div id="manage_subcontainer"></div>
    <div id="manage_footer">
        Console: <button id="console_toggle" class="" type="button" value="0">show</button>
    </div>
</div>

<div id="application-loading">
  Loading Site Management...
</div>

<!-- YUI Seed -->
<script type="text/javascript" src="http://yui.yahooapis.com/<%= $yui_version %>/build/yui/yui.js"></script>
<script type="text/javascript" src="/ic/js/manage.js"></script>

</body>
</html>
