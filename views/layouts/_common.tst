<%=
    if (defined $html_header_content and $html_header_content ne '') {
        $html_header_content
    }
    elsif (defined $html_header_component) {
        $html_header_component->content
    }
%>
<%= $action_content %>
<%=
    if (defined $html_footer_content and $html_footer_content ne '') {
        $html_footer_content
    }
    elsif (defined $html_footer_component) {
        $html_footer_component->content
    }
%>
