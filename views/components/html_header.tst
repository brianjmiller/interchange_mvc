<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title><%= $page_title %></title>

    <link rel="stylesheet" type="text/css" href="/ic/styles/base.css" />

    <% for my $element (@{ $stylesheets }) { %>
        <link rel="stylesheet" type="text/css" href="/<%= $element->{kind} %>/styles/<%= $element->{path} %>" />
    <% } %>

    <% for my $element (@{ $js_libs }) { %>
        <script type="text/javascript" src="/<%= $element->{kind} %>/js/<%= $element->{path} %>"></script>
    <% } %>
</head>

<body <%= $body_args %>>

