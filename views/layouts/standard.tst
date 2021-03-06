<%=
    if (defined $html_header_content and $html_header_content ne '') {
        $html_header_content
    }
    elsif (defined $html_header_component) {
        $html_header_component->content
    }
%>
<div id="standard_layout_wrapper_div">
    <div id="primary_header_div">
        <div class="yui-g">
            <div id="content_title_div" class="yui-u first">
                <%= $content_title %>
            </div>
            <div id="content_subtitle_div" class="yui-u">
                <%= $content_subtitle %>
            </div>
        </div>
    </div>
    <div id="primary_content_div" class="yui-g">
        <% if ($error_messages and @$error_messages) { %>
            <div id="error_messages">
                <h3>There were errors in your request:</h3>
                <ul>
                <% for my $msg (@$error_messages) { %>
                    <li><%= escape_html($msg) %></li>
                <% } %>
                </ul>
            </div>
            <br />
        <% } %>
        <% if ($status_messages and @$status_messages) { %>
            <div id="status_messages">
                <ul>
                    <% for my $msg (@$status_messages) { %>
                        <li><%= escape_html($msg) %></li>
                    <% } %>
                </ul>
            </div>
            <br />
        <% } %>
        <%= $action_content %>
    </div>
    <div id="primary_footer_div">
    </div>
</div>
<%=
    if (defined $html_footer_content and $html_footer_content ne '') {
        $html_footer_content
    }
    elsif (defined $html_footer_component) {
        $html_footer_component->content
    }
%>
