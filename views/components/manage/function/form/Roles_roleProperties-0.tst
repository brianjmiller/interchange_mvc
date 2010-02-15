<input type="hidden" name="_work_around_ic_id" value="<%= $f->{_work_around_ic_id} %>" />
<tr>
    <td class="manage_form_table_label_cell">Display Label:</td>
    <td class="manage_form_table_input_cell"><input type="text" name="display_label" value="<%= $f->{display_label} %>" size="50" maxlength="50" /></td>
</tr>
<tr>
    <td class="manage_form_table_input_cell" colspan="2">
        Description:
        <br />
        <textarea name="description" rows="5" cols="50" /><%= $f->{description} %></textarea>
    </td>
</tr>
