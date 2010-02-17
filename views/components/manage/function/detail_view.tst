<!-- views/components/manage/function/detail_view.tst -->
<table id="detail_table" style="width: 100%;">
    <tr>
        <td class="detail_table_left_cell">
            <table class="detail_sub_table">
                <tr>
                    <td class="detail_table_title_cell" colspan="2">
                        Primary Key Fields and Values
                    </td>
                </tr>
                <% for my $element (@$pk_settings) { %>
                    <tr>
                        <td class="detail_table_datum_cell"><%= $element->{field} %>:&nbsp;</td>
                        <td class="detail_table_datum_cell"><%= $element->{value} %></td>
                    </tr>
                <% } %>
            </table>
            <br />
            <% if (@$foreign_objects) { %>
                <table class="detail_sub_table">
                    <tr>
                        <td class="detail_table_title_cell" colspan="2">
                            Referenced Objects
                        </td>
                    </tr>
                    <% for my $element (@$foreign_objects) { %>
                        <tr>
                            <td class="detail_table_datum_cell"><%= $element->{field} %>:&nbsp;</td>
                            <td class="detail_table_datum_cell"><%= $element->{value} %></td>
                        </tr>
                    <% } %>
                </table>
                <br />
            <% } %>
            <table class="detail_sub_table">
                <tr>
                    <td class="detail_table_title_cell" colspan="2">
                        Other Fields and Values
                    </td>
                </tr>
                <% for my $element (@$other_settings) { %>
                    <tr>
                        <td class="detail_table_datum_cell"><%= $element->{field} %>:&nbsp;</td>
                        <td class="detail_table_datum_cell"><%= $element->{value} %></td>
                    </tr>
                <% } %>
            </table>
            <br />
            <%= $hook_top_left_content %>
        </td>
        <td class="detail_table_right_cell">
            <% if (@$action_links) { %>
                <table class="detail_sub_table">
                    <tr>
                        <td class="detail_table_title_cell">
                            Actions
                        </td>
                    </tr>
                    <% for my $element (@$action_links) { %>
                        <tr>
                            <td class="detail_table_datum_cell"><%= $element->{html_link} %></td>
                        </tr>
                    <% } %>
                </table>
                <br />
            <% } %>
            <table class="detail_sub_table">
                <tr>
                    <td class="detail_table_title_cell" colspan="2">
                        Auto Fields and Values
                    </td>
                </tr>
                <% for my $element (@$auto_settings) { %>
                    <tr>
                        <td class="detail_table_datum_cell"><%= $element->{field} %>:&nbsp;</td>
                        <td class="detail_table_datum_cell"><%= $element->{value} %></td>
                    </tr>
                <% } %>
            </table>
            <br />
            <%= $hook_top_right_content %>
        </td>
    </tr>
    <% if (defined $hook_bottom_content and $hook_bottom_content ne '') { %>
        <tr>
            <td colspan="2">
                <%= $hook_bottom_content %>
            </td>
        </tr>
    <% } %>
</table>
