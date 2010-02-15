<input type="hidden" name="_work_around_ic_id" value="<%= $f->{_work_around_ic_id} %>" />
<input type="hidden" name="role_id" value="<%= $f->{role_id} %>" />
<tr>
    <td class="manage_form_table_label_cell">Right Type: </td>
    <td class="manage_form_table_input_cell">
        <select name="right_type_id">
            <option value=""> Choose </option>
            <% for my $option (@{ $opts->{right_types} }) { %>
                <option value="<%= $option->{value} %>"<%= $option->{selected} %>><%= $option->{display} %></option>
            <% } %>
        </select>
    </td>
</tr>
<tr>
    <td class="manage_form_table_label_cell">Is Granted? </td>
    <td class="manage_form_table_input_cell">
        <input type="radio" name="is_granted" value="1"<% if ($f->{is_granted}) { %> checked="checked"<% } %> /> Yes
        <input type="radio" name="is_granted" value="0"<% if (not defined $f->{is_granted} or not $f->{is_granted}) { %> checked="checked" <% } %> /> No
    </td>
</tr>
