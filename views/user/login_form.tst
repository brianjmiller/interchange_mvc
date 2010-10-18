<form 
    id="user_login_form"
    method="post"
    action="<%=
        url(
            controller => 'user',
            action     => 'login_auth',
            parameters => {
                method => 'post',
            },
            secure => 1,
        );
    %>"
>
    <% if (defined $referer) { %>
        <input type="hidden" name="redirect" value="<%= $referer %>" />
    <% } %>
    <table id="login_form_table">
        <tr>
            <td class="login_form_table_label_cell">Username: </td>
            <td class="login_form_table_input_cell">
                <input class="login_form_input" type="text" name="username" value="" />
            </td>
        </tr>
        <tr>
            <td class="login_form_table_label_cell">Password: </td>
            <td class="login_form_table_input_cell">
                <input class="login_form_input" type="password" name="password" value="" />
            </td>
        </tr>
        <tr>
            <td class="login_form_table_submit_cell" colspan="2">
                <input type="submit" value="Login" />
            </td>
        </tr>
    </table>
</form>
