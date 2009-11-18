my_arg: <%= $my_arg %>
my_view: <%= $my_view %>
cgi_hash: <%=
	join(
		' ',
		map(
			{ "$_ $cgi_hash->{$_}" }
			sort({ $a cmp $b } keys %$cgi_hash),
		),
	)
%>
url_hash: <%=
	join(
		' ',
		map(
			{ "$_ $url_hash->{$_}" }
			sort({ $a cmp $b } keys %$url_hash),
		),
	)
%>
