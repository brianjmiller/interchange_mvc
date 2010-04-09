<form 
    id="account_maintenance_form"
    method="post"
    action="<%=
        url(
            controller => 'user',
            action     => 'account_maintenance_save',
            parameters => {
                method => 'post',
            },
            secure => 1,
        );
    %>"
>
    <input type="hidden" name="_step" value="1" />

    <table class="menu_sub_content_table" cellspacing="0">
        <tr>
            <td class="account_maintenance_title_cell" colspan="2">
                <span class="emphasized">Essential Details</span>
            </td>
        </tr>
        <tr>
            <td class="account_maintenance_label_cell">Username:</td>
            <td class="account_maintenance_input_cell">
                <input type="text" name="username" value="<%= $f->{username} %>" size="40" maxlength="100" />
            </td>
        </tr>
        <tr>
            <td class="account_maintenance_label_cell">E-mail Address:</td>
            <td class="account_maintenance_input_cell">
                <input type="text" name="email" value="<%= $f->{email} %>" size="40" maxlength="100" />
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <br />
                <span class="mini">NOTE: Only enter password if a change is desired, leave blank to retain current password.</span>
            </td>
        </tr>
        <tr>
            <td class="account_maintenance_label_cell">New Password:</td>
            <td class="account_maintenance_input_cell">
                <input type="password" name="new_password" value="" size="32" maxlength="100" />
            </td>
        </tr>
        <tr>
            <td class="account_maintenance_label_cell">Confirm New Password:</td>
            <td class="account_maintenance_input_cell">
                <input type="password" name="con_password" value="" size="32" maxlength="100" />
            </td>
        </tr>
        <tr>
            <td class="account_maintenance_submit_cell" colspan="2" style="text-align: center;">
                <br />
                <input type="submit" value="Save Changes" />
            </td>
        </tr>
    </table>
</form>
