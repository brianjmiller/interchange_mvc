<html>
<head>
    <title>An exception occurred</title>
</head>

<body>

<h2>An exception was thrown:</h2>

<pre>
    <%= $exception->error %>
</pre>

<a href="<%= url( controller => 'home', action => 'basic', secure => 1 ) %>">Index</a>

</body>
</html>
