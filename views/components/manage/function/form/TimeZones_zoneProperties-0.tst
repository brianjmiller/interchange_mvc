<tr>
    <td class="manage_form_table_label_cell">Code:<br ><span class="mini">(For Example: "US/Eastern")</td>
    <td class="manage_form_table_input_cell"><input type="text" name="code" value="<%= $f->{code} %>" size="50" maxlength="70" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Is Visible? </td>
    <td class="manage_form_table_input_cell">
        <input type="radio" name="is_visible" value="1"<% if ($f->{is_visible}) { %> checked="checked"<% } %> /> Yes
        <input type="radio" name="is_visible" value="0"<% if (not defined $f->{is_visible} or not $f->{is_visible}) { %> checked="checked" <% } %> /> No
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">UTC Offset: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="utc_offset" value="<%= $f->{utc_offset} %>" size="3" maxlength="3" /></td>
</tr>
