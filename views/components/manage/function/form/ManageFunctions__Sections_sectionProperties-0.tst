<tr>
    <td class="manage_form_table_label_cell">Section Code: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="code" value="<%= $f->{code} %>" size="30" maxlength="30" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Display Label: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="display_label" value="<%= $f->{display_label} %>" size="20" maxlength="20" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Status: </td>
    <td class="manage_form_table_input_cell">
        <select name="status">
            <option value=""> Choose </option>
            <% for my $option (@{ $opts->{statuses} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
</tr>
