<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <title>IC: Management Area</title>

    <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?3.1.1/build/cssreset/reset-min.css&3.1.1/build/cssfonts/fonts-min.css&3.1.1/build/cssgrids/grids-min.css&3.1.1/build/cssbase/base-min.css">

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
    <div id="manage_quick">
      <ul>
        <li><a href="#">Go to Order #321</a></li>
        <li><a href="#">Go to Product SKU:a321</a></li>
        <li><a href="#">Bulk Customer Order Fraud Check (2)</a></li>
        <li><a href="#">Create Stock Orders (Customer Orders Pending: 4)</a></li>
      </ul>
    </div>
    <div id="manage_menu"></div>
    <div id="manage_datatable"></div>
    <div id="manage_detail"></div>
    <div id="manage_subcontainer"></div>
    <div id="manage_footer">
        Console: <button id="console_toggle" class="" type="button" value="0">show</button>
    </div>
</div>

<div class="please-wait display-while-loading">
  Application loading...
</div>

<!-- YUI Seed -->
<script type="text/javascript" src="http://yui.yahooapis.com/3.1.1/build/yui/yui.js"></script>
<script type="text/javascript" src="/ic/js/manage.js"></script>

</body>
</html>
