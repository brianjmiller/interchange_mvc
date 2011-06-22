#!/usr/local/bin/perl
use strict;
use warnings;

use Interchange::Deployment;
use lib (__FILE__ =~ /^(.+?)\.t/)[0] . '/lib';

my $path = __FILE__;
$path =~ s/\.t$//;
my $view_path = $path . '/views';

use Test::More (tests => 27);
my $class = 'IC::Component';
my $binding_class = 'IC::Controller::Route::Binding';
BEGIN: {
    use_ok( $class );
}

my $comp = $class->new;
isa_ok( $comp, $class );

my %binding = (
    controller  => 'controller',
    action      => 'action',
    url_names   => [qw(a b c)],
    controller_parameters   => {
        a   => 'a',
        b   => 'b',
    },
);

my $binding = $comp->binding_transform( \%binding );
isa_ok( $binding, $binding_class );
compare_moose_attributes(
    $binding,
    $binding_class->new( %binding ),
    'binding_transform() properly auto-instantiates binding object',
);

cmp_ok(
    $comp->binding_transform( $binding ),
    '==',
    $binding,
    'binding_transform() binding object passes through',
);

$comp->binding( $binding );
cmp_ok(
    $comp->binding,
    '==',
    $binding,
    'binding() set',
);

$comp->binding( \%binding );
compare_moose_attributes(
    $comp->binding,
    $binding_class->new( %binding ),
    'binding() set with transform',
);

eval {
    $comp->binding( 'foo' );
};
ok(
    $@,
    'binding() set throws exception with invalid input',
);

# local check for register_bindings and resulting behavior...
my @bindings = qw(a b c);
package Bogus::Foo;
use Moose;
extends ($class);
__PACKAGE__->register_bindings(@bindings);
1;

package main;

my $count;
$comp = Bogus::Foo->new;
for my $attrib (@bindings) {
    my $sub = $comp->can($attrib);
    $comp->$sub( \%binding );
    compare_moose_attributes(
        $comp->$sub(),
        $binding_class->new(\%binding),
        'register_bindings() magical behaviors ' . ++$count
    );
}

my %params;
$params{$_} = { %binding } for @bindings;
$comp = Bogus::Foo->new( %params );
$count = 0;
for my $attrib (@bindings) {
    my $sub = $comp->can($attrib);
    compare_moose_attributes(
        $comp->$sub(),
        $binding_class->new(\%binding),
        'register_bindings() magical behaviors from constructor ' . ++$count,
    );
}

use Controller;
use Component;

my $controller_specific = Controller->new( view_path => $view_path, );
my $controller_instance = Controller2->new( view_path => $view_path, );
my $controller_default = Controller3->new( view_path_ => $view_path, );
my $controller_no_views = ControllerNoViews->new(
    view_path => $view_path,
);

$controller_specific->view_path( $view_path );
$controller_instance->view_path( $view_path );
$controller_default->view_path( $view_path );
$controller_no_views->view_path( $view_path );

my $base_view = 'base';
my $controller_view = 'controller';

my %base_params = (
    a => {
        href => 'http://a.com',
    },
    b => {
        href => 'http://b.com',
    },
    c => {
        href => 'http://c.com',
    },
    binding => {
        href => 'http://binding.com',
    },
);

$comp = Component->new( %base_params );
eval { $comp->render( view => $base_view, ) };
ok(
    $@,
    'render() throws exception with no controller',
);
IC::Controller::HelperBase->bind_to_controller($controller_default);
my $content = $comp->render( view => $controller_view, );
my ($controller_default_regex,
    $controller_specific_regex,
    $controller_instance_regex,
    $controller_no_views_regex,
) = map {
    $_->view_path( $view_path );
    my $pattern = '(?:^|\s)controller='
        . $_->registered_name
        . '(?:\s|$)'
    ;
    qr{$pattern};
} (
    $controller_default,
    $controller_specific,
    $controller_instance,
    $controller_no_views,
);

cmp_ok(
    $content,
    '=~',
    $controller_default_regex,
    'render() defaults to bound controller',
);

$comp->controller( $controller_instance );
$content = $comp->render( view => $controller_view, );
cmp_ok(
    $content,
    '=~',
    $controller_instance_regex,
    'render() overrides default with instance controller',
);

my $passed;
$content = $comp->render( view => $controller_view, controller => $controller_specific, );
cmp_ok(
    $content,
    '=~',
    $controller_specific_regex,
    'render() overrides all with specific controller parameter',
) && $passed++;

$content = $comp->render( view => $controller_view, controller => $controller_no_views, );
cmp_ok(
    $content,
    '=~',
    $controller_no_views_regex,
    'render() uses component/ view directory as fallback to controller/ directory',
) && $passed++;

ok(
    $passed == 2,
    'render() prioritizes controller/ view directory',
);

$comp->controller( $controller_instance );
$content = $comp->render( view => [ $controller_default->registered_name . "/$controller_view", ], );
cmp_ok(
    $content,
    '=~',
    $controller_default_regex,
    'render() accepts literal paths via array',
);

$content = $comp->render( view => $base_view );
cmp_ok(
    $content,
    '=~',
    $comp->base_view_regex,
    'render() marshalls object attributes by default',
);

$content = $comp->render(
    view => $base_view,
    context => {
        controller => 1,
        a => 2,
        b => 3,
        c => 4,
        binding => 5,
    },
);
cmp_ok(
    $content,
    '=~',
    qr{(?:^|\s+)controller=1\s+a=2\s+b=3\s+c=4\s+binding=5(?:\s+|$)},
    'render() overrides marshal with context parameter',
);

$base_params{controller} = $controller_instance;
$base_params{view} = $base_view;
$comp = Component->new( %base_params );
my $regex = $comp->base_view_regex;
$content = $comp->content( %base_params );
cmp_ok(
    $content,
    '=~',
    $regex,
    'content() passes through to render properly from object',
);

my $full_content = Component->content( %base_params );
cmp_ok(
    $full_content,
    'eq',
    $content,
    'content() results in same content when invoked fully through package',
);

is(
    ($comp->can('logger') && $comp->logger) || 'not set on object',
    (UNIVERSAL::can('IC::Log', 'logger') && IC::Log->logger) || 'not set in package',
    'logger() default setting',
);

$comp->can('set_logger') && $comp->set_logger( IC::Log::Base->new );
is(
    ($comp->can('logger') && $comp->logger) || 'not set via logger',
    ($comp->can('get_logger') && $comp->get_logger) || 'get_logger not available',
    'logger() instance setting',
);

sub compare_moose_attributes {
    my ($test, $model, $name) = @_;
    my (%test, %model);

=cut

    for my $pair ([$test, \%test,], [$model, \%model],) {
        for my $attrib ($pair->[0]->meta->get_all_attributes) {
            my $sub = $pair->[0]->can($attrib->name);
            $pair->[1]->{$attrib->name} = $pair->[0]->$sub();
        }
    }

=cut

    return is_deeply(
        $test,
        $model,
        $name,
    );
}
