package IC::Email;

use strict;
use warnings;

use MIME::Lite;

use IC::Config;

use Moose;

has 'intercept' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'override_intercept' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has 'from' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'subject_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'subject' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'body' => (
    is      => 'rw',
);
has 'addresses' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has 'bcc' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'reply_to' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'attachments' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

no Moose;

sub BUILD {
    my $self = shift;

    #
    # the intercept should be respected regardless of whether we are in a camp
    #
    $self->intercept( IC::Config->smart_variable('MV_EMAIL_INTERCEPT') );

    if (Bikes::Config->is_live) {
    }
    else {
        my $camp = Bikes::Config->camp_number;

        $self->subject_prefix("[camp$camp] " . ($self->subject_prefix || ''));

        #
        # in a camp we should *always* intercept, last resort
        # send to the camp's owner account
        #
        if ($self->intercept eq '') {
            my $camp_user = Camp::Master::set_camp_user_info( Camp::Master::camp_user() );

            $self->intercept( $camp_user->{admin_email} );
        }
    }

    return;
}

sub send {
    my $self = shift;
    my (@addresses) = @_;

    unless (@addresses or @{ $self->addresses }) {
        IC::Exception->throw('Invalid or missing addresses');
    }

    my %addtl_headers = ();

    my $data;
    if (ref $self->body eq 'HASH') {
        $data                = $self->body->{data};
        $addtl_headers{Type} = $self->body->{type};
    }
    elsif (ref $self->body eq 'ARRAY') {
        $data = join '', @{ $self->body };
    }
    elsif ($self->body ne '') {
        $data = $self->body;
    }
    else {
        IC::Exception->throw('Invalid or missing body');
    }

    my $subject = $self->subject_prefix . $self->subject;
    my $bcc      = $self->bcc;
    my $reply_to = $self->reply_to;

    my $to;
    if (@addresses) {
        $to = join ', ', @addresses;
    }
    if (@{ $self->addresses }) {
        $to .= ', ' if $to ne '';
        $to .= join ',', @{$self->{addresses}};
    }
	unless ($self->override_intercept) {
    	if ($self->intercept ne '') {
       	 	#warn 'Intercept in place: ' . $self->intercept;
        	$addtl_headers{'X-Intercept'} = $to;
            $addtl_headers{'X-Bcc'}       = $bcc;
        	$to                           = $self->intercept;
        	$bcc                          = $self->intercept;

            if ($reply_to ne '') {
                $addtl_headers{'X-Reply-To'} = $reply_to;
                $reply_to                    = $self->intercept;
            }
    	}
	}
    if ($reply_to ne '') {
        $addtl_headers{'Reply-To'} = $reply_to;
    }

    my $message = MIME::Lite->new(
        To      => $to,
        From    => $self->from,
        Subject => $subject,
        Data    => $data,
        Bcc     => $bcc,
        %addtl_headers,
    );
    unless (defined $message) {
        IC::Exception->throw( q{Can't instantiate mail message} );
    }

    if (@{ $self->attachments }) {
        for my $attachment (@{ $self->attachments }) {
            my $part = MIME::Lite->new(
                Type => $attachment->{type},
                Data => $attachment->{data},
            );
            $part->filename($attachment->{filename});

            $message->attach($part);
        }
    }

    $message->send;

    return;
}

1;

#############################################################################
__END__
