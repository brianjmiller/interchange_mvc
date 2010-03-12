<input type="hidden" name="resource" value="<%= $f->{resource} %>" />
<input type="hidden" name="tmp_filename" value="<%= $f->{tmp_filename} %>" />
<tr>
    <td class="manage_form_table_label_cell">
        Confirm file:
    </td>
    <td class="manage_form_table_input_cell">
        <%= $opts->{upload_confirm_file} %>
    </td>
</tr>
<% if (defined $opts->{attributes}) { %>
    <tr>
        <td colspan="2">
            <br />
            <span class="emphasized">Attributes</span>
            <br />
            <table>
                <% for my $attribute (@{ $opts->{attributes} }) { %>
                    <input type="hidden" name="_attr_<%= $attribute->{id} %>" value="<%= $attribute->{value} %>" />
                    <tr>
                        <td><%= $attribute->{display_label} %>: </td>
                        <td><%= $attribute->{value} %></td>
                    </tr>
                <% } %>
            </table>
        </td>
    </tr>
<% } %>
