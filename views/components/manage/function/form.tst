<!-- views/components/manage/function/form.tst -->
<% unless ($provided_form) { %>
    <form
        name="manage_function_form"
        method="POST" 
        action="<%=
            url(
                controller => 'manage',
                action     => 'function',
                parameters => {
                    _function => $_function,
                    _step     => $_step,
                    method    => 'post',
                },
                secure => 1,
            );
        %>"
        <% if (defined $form_enctype) { %>
            enctype="<%= $form_enctype %>"
        <% } %>
    >
<% } %>

<% if (defined $_properties_mode) { %>
    <input type="hidden" name="_properties_mode" value="<%= $_properties_mode %>" />
<% } %>

<% if (defined $form_referer) { %>
    <input type="hidden" name="redirect_referer" value="<%= $form_referer %>" />
<% } %>

<%
    if (defined $pk_pairs and %$pk_pairs) {
        while (my ($key, $val) = each %$pk_pairs) {
            %><input type="hidden" name="<%= $key %>" value="<%= $val %>" /><%
        }
    }
%>

<table id="manage_form_table" cellspacing="0">
    <%=
        my $context = {
            f    => $f,
            opts => $include_options,
        };
        if (defined $_properties_mode) {
            $context->{mode} = $_properties_mode;
        }
        render(
            view    => "components/manage/function/form/$form_include",
            context => $context,
        );
    %>
    <% unless ($provided_form) { %>
        <tr>
            <td class="manage_form_table_button_cell_centered">
                <input type="submit" value="<%= (defined $form_button_value ? $form_button_value : 'Submit') %>" />
            </td>
        </tr>
    <% } %>
</table>

<% unless ($provided_form) { %>
    </form>
<% } %>
