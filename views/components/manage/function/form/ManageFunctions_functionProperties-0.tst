<tr>
    <td class="manage_form_table_label_cell">Function Label: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="code" value="<%= $f->{code} %>" size="50" maxlength="70" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Display Label: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="display_label" value="<%= $f->{display_label} %>" size="50" maxlength="100" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Select Section: </td>
    <td class="manage_form_table_input_cell">
        <select name="section_code">
            <option value=""> Choose </option>
            <% for my $option (@{ $opts->{sections} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">For developers only: </td>
    <td class="manage_form_table_input_cell">
        <input type="radio" name="developer_only" value="1"<% if ($f->{developer_only}) { %> checked="checked"<% } %> /> Yes
        <input type="radio" name="developer_only" value="0"<% if (not defined $f->{developer_only} or not $f->{developer_only}) { %> checked="checked" <% } %> /> No
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">In Management Menu: </td>
    <td class="manage_form_table_input_cell">
        <input type="radio" name="in_menu" value="1"<% if ($f->{in_menu}) { %> checked="checked"<% } %> /> Yes
        <input type="radio" name="in_menu" value="0"<% if (not defined $f->{in_menu} or not $f->{in_menu}) { %> checked="checked" <% } %> /> No
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Sort Order: </td>
    <td class="manage_form_table_input_cell"><input type="text" name="sort_order" value="<%= $f->{sort_order} %>" size="5" maxlength="5" /></td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Help Copy: </td>
    <td class="manage_form_table_input_cell">
        <textarea name="help_copy" rows="5" cols="50" /><%= $f->{help_copy} %></textarea>
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Extra Parameters: </td>
    <td class="manage_form_table_input_cell">
        <textarea name="extra_params" rows="2" cols="50" /><%= $f->{extra_params} %></textarea>
    </td>
</tr>

