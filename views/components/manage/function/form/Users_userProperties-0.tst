<input type="hidden" name="role_id" value="<%= $f->{role_id} %>" />
<tr>
    <td class="manage_form_table_label_cell">Username:</td>
    <td class="manage_form_table_input_cell"><input type="text" name="username" value="<%= $f->{username} %>" size="30" maxlength="30" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">E-mail Address:</td>
    <td class="manage_form_table_input_cell"><input type="text" name="email" value="<%= $f->{email} %>" size="50" maxlength="100" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Select Status: </td>
    <td class="manage_form_table_input_cell">
        <select name="status_code">
            <option value=""> Choose </option>
            <% for my $option (@{ $opts->{statuses} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Select Time Zone: </td>
    <td class="manage_form_table_input_cell">
        <select name="time_zone_code">
            <option value=""> Choose </option>
            <% for my $option (@{ $opts->{time_zones} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
</tr>
<% if ($mode eq 'edit') { %>
    <tr>
        <td class="manage_form_table_label_cell" colspan="2">
            <br />
            (Leave password fields blank if not changing)
        </td>
    </tr>
<% } %>
<tr>
    <td class="manage_form_table_label_cell">New Password:</td>
    <td class="manage_form_table_input_cell"><input type="password" name="new_password" value="" size="20" maxlength="20" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Confirm Password:</td>
    <td class="manage_form_table_input_cell"><input type="password" name="con_password" value="" size="20" maxlength="20" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell" colspan="2"><br /></td>
</tr>
