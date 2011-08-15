<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
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
    # This is a global used by the manage application to configure its various
    # elements and to allow customization of the components loaded by YUI
    # Pulling this out and storing it in the view means we can adjust it through
    # the controller's context like any other view.
    #
    # This view expects it to be a JSON encoded object string, the upstream
    # controller should be handling that for us.
%>
<script type="text/javascript">
    var IC_manage_config = <%= $IC_manage_config %>;
</script>

<!-- YUI Seed, Loader, and our primary source -->
<script type="text/javascript" src="/combo?ic/vendor/yui3/build/yui/yui-min.js&ic/vendor/yui3/build/loader/loader-min.js&ic/js/manage.js"></script>

</body>
</html>
