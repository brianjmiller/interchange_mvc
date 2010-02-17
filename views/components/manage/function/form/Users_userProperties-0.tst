<input type="hidden" name="_work_around_ic_id" value="<%= $f->{_work_around_ic_id} %>" />
<input type="hidden" name="version_id" value="<%= $f->{version_id} %>" />
<tr>
    <td class="manage_form_table_label_cell">Username:</td>
    <td class="manage_form_table_input_cell"><input type="text" name="username" value="<%= $f->{username} %>" size="30" maxlength="30" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">E-mail Address:</td>
    <td class="manage_form_table_input_cell"><input type="text" name="email" value="<%= $f->{email} %>" size="50" maxlength="100" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Select Role: </td>
    <td class="manage_form_table_input_cell">
        <select name="role_id">
            <option value="_new"> Create New </option>
            <% for my $option (@{ $opts->{roles} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
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
    <td class="manage_form_table_label_cell">Select Password Hash Kind: </td>
    <td class="manage_form_table_input_cell">
        <select name="password_hash_kind_code">
            <option value="sha1">SHA-1</option>
            <option value="md5">MD5</option>
            <option value="pass_through">None (Stored as plain text)</option>
        </select>
    </td>
</tr>
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
