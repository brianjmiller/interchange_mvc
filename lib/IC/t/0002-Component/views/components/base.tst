<% 
  sub linky {
      my $obj = shift;
      return $obj if !ref($obj);
      return url( binding => $obj );
  }
%>controller=<%= ref($controller) ? $controller->registered_name : $controller %>
a=<%= linky($a); %>
b=<%= linky($b); %>
c=<%= linky($c); %>
binding=<%= linky($binding); %>
