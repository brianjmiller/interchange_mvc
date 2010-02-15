<!-- views/manage/menu.tst -->
<table id="manage_menu_table" style="width: 100%;">
    <tr>
        <td id="manage_menu_table_left_cell" class="half_top">
            <% for my $section (@$menu_left) { %>
                <span class="emphasized"><%= $section->{name} %></span>
                <br />
                <% for my $link (@{ $section->{links} }) { %>
                    <a href="<%= $link->{url} %>"><%= $link->{display_label} %></a><br />
                <% } %>
                <br />
            <% } %>
        </td>
        <td id="manage_menu_table_right_cell" class="half_top">
            <% for my $section (@$menu_right) { %>
                <span class="emphasized"><%= $section->{name} %></span>
                <br />
                <% for my $link (@{ $section->{links} }) { %>
                    <a href="<%= $link->{url} %>"><%= $link->{display_label} %></a><br />
                <% } %>
                <br />
            <% } %>
        </td>
    </tr>
</table>
