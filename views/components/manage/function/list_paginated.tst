<!-- views/components/manage/function/list_paginated.tst -->
<table id="list_table" cellpadding="3" cellspacing="0" style="width: 100%;">
    <tr>
        <% for my $header (@$headers) { %>
            <td class="list_table_title_cell<%= $header->{class_opt} %>">
                <%= $header->{display} %>
            </td>
        <% } %>
        <td class="list_table_title_cell_centered">Options</td>
    </tr>
    <% my $list_increment = 0; %>
    <% for my $row (@$rows) { %>
        <%
            $list_increment++;
            my $label = $list_increment % 2 ? 'odd' : 'even';
        %>
        <tr>
            <% for my $field (@$fields) { %>
                <td class="list_table_datum_cell_<%= $label %>"><%= $row->{$field} %></td>
            <% } %>
            <td class="list_table_options_cell_<%= $label %>">
                <% for my $link (@{ $row->{function_options} }) { %>
                    <%= $link %>
                <% } %>
            </td>
        </tr>
    <% } %>
</table>
