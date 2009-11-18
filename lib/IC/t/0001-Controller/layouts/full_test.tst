action: <%= $parameters->{action} %>
controller: <%= $parameters->{controller} %>
request: <%= ref($request) || $request %>
route_handler: <%= $route_handler %>
<%= $action_content %>
