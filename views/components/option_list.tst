<% for my $option (@$options) { %>
    <option value="<%= $option->{value} %>"<%= $option->{selected} ? ' selected="selected"' : '' %>><%= $option->{label} %></option>
<% } %>
