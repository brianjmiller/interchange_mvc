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
    <% if (defined $file_resources) { %>
        <tr>
            <td colspan="2">
                <br />
                <table class="detail_sub_table">
                    <tr>
                        <td class="detail_table_title_cell" colspan="3">
                            File Resources
                        </td>
                    </tr>
                    <% for my $file_res (@$file_resources) { %>
                        <tr>
                            <td class="detail_table_datum_cell"><%= $file_res->{display} %></td>
                            <td class="detail_table_datum_cell">
                                &nbsp;&nbsp;<%= $file_res->{link} %>
                            </td>
                            <td class="detail_table_datum_cell">
                                &nbsp;&nbsp;<%= $file_res->{drop_link} %>
                            </td>
                        </tr>
                        <tr>
                            <td class="detail_table_datum_cell" style="padding-left: 20px; padding-bottom: 10px;" colspan="3">
                                <% if (defined $file_res->{attrs}) { %>
                                    <table>
                                        <tr>
                                            <td colspan="2"><span class="emphasized">Attributes</span></td>
                                        </tr>
                                        <% for my $attr (@{ $file_res->{attrs} }) { %>
                                            <tr>
                                                <td><%= $attr->{display_label} %>:&nbsp;</td>
                                                <td><%= $attr->{value} %></td>
                                            </tr>
                                        <% } %>
                                    </table>
                                    <br />
                                <% } %>

                                <% if (defined $file_res->{url}) { %>
                                    <%= $file_res->{url} %>
                                <% } else { %>
                                    <span class="italicized">No file yet stored.</span>
                                <% } %>
                            </td>
                        </tr>
                    <% } %>
                </table>
            </td>
        </tr>
    <% } %>
    <% if (defined $hook_bottom_content and $hook_bottom_content ne '') { %>
        <tr>
            <td colspan="2">
                <%= $hook_bottom_content %>
            </td>
        </tr>
    <% } %>
    <% if (defined $action_log) { %>
        <tr>
            <td colspan="2">
                <br />
                <table class="detail_sub_table">
                    <tr>
                        <td class="detail_table_title_cell" colspan="3">Log</td>
                    </tr>
                    <% for my $log_line (@$action_log) { %>
                        <tr>
                            <td class="detail_table_datum_cell" style="padding-right: 15px; white-space: nowrap;">
                                <%= $log_line->{label} %>
                            </td>
                            <td class="detail_table_datum_cell" style="padding-right: 15px;">
                                <%= $log_line->{by_name} %>
                            </td>
                            <td class="detail_table_datum_cell" style="padding-right: 15px; white-space: nowrap;">
                                <%= $log_line->{details} %>
                            </td>
                            <td class="detail_table_datum_cell" style="padding-right: 15px;">
                                <%= $log_line->{date_created} %>
                            </td>
                            <td class="detail_table_datum_cell" style="padding-right: 15px;">
                                <%= $log_line->{content} %>
                            </td>
                        </tr>
                    <% } %>
                </table>
            </td>
        </tr>
    <% } %>
</table>
