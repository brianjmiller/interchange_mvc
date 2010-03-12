<html>
<head>
    <title>An exception occurred</title>
</head>

<body>

<script type="text/javascript">
    function toggle_trace_details() {
        var el = document.getElementById('exception_stack_trace');
        var new_display = el.style.display == 'block' ? 'none' : 'block';

        el.style.display = new_display;
        return false;
    }
</script>

<div class="error" style="text-align: left;">
    <span class="emphasized">Caught Exception</span>
    <br />
    <br />
    <span style="font-weight: normal;">
        Kind: <%= $type %>
        <br />
        Info: <%= $exception %>
        <br />
        <br />
        <% if ($trace ne '') { %>
            Trace: <a href="#" onclick="return toggle_trace_details()">Details</a>
            <pre id="exception_stack_trace" style="overflow: scroll; font-size: x-small; font-face: sans-serif; display: none">
                <%= $trace %>
            </pre>
        <% } %>
    </span>
    <br />
    <br />
</div>

</body>
</html>
