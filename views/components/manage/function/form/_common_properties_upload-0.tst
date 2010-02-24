<input type="hidden" name="resource" value="<%= $f->{resource} %>" />
<tr>
    <td class="manage_form_table_label_cell">
        Select file for upload:
    </td>
    <td class="manage_form_table_label_cell">
        <input type="file" name="uploaded_file" />
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
                    <tr>
                        <td><%= $attribute->{display_label} %>: </td>
                        <td>
                            <% if ($attribute->{kind} eq 'numeric') { %>
                                <input type="text" name="_attr_<%= $attribute->{id} %>" value="<%= $attribute->{value} %>" size="7" maxlength="7" />
                            <% } %>
                        </td>
                    </tr>
                <% } %>
            </table>
        </td>
    </tr>
<% } %>
