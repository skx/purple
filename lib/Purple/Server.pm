
=head1 NAME

Purple::Server - Dancer Web-UI.

=head1 DESCRIPTION

This module implements our HTTP-interface, which serves two purposes:

=over 8

=item Handle the submission of JSON-encoded events

=item  Handle the web-based user interface.

=back

=cut

package Purple::Server;

use strict;
use warnings;

use Dancer;
use Dancer::Plugin::Auth::Extensible;
use HTML::Entities;


set show_errors => 1;
use Purple::Alerts;


# Show the web-interface.
get '/' => require_login sub {
    send_file 'index.html';
};


# Show the login-page.
get '/login' => sub {
    send_file 'login.html';
};

post '/login' => sub {
    my ( $success, $realm ) =
      authenticate_user( params->{ username }, params->{ password } );
    if ($success)
    {
        session logged_in_user       => params->{ username };
        session logged_in_user_realm => $realm;

        # other code here
        redirect '/';
    }
    else
    {
        # authentication failed
        send_file 'login.html';
    }
};

# Handle a logout
any '/logout' => sub {
    session logged_in_user       => undef;
    session logged_in_user_realm => undef;

    session->destroy;
    session->flush;
    send_file 'logout.html';
};


# Acknowledge an event which is in the raised state.
get '/acknowledge/:id' => require_login sub {
    my $tmp = Purple::Alerts->new();
    my $out = $tmp->acknowledgeAlert( params->{ 'id' } );
    return ( redirect '/' );
};


# Clear an event which is in the raised/pending state.
get '/clear/:id' => require_login sub {
    my $tmp = Purple::Alerts->new();
    my $out = $tmp->clearEvent( params->{ 'id' } );
    return ( redirect '/' );
};

# Raise an event which is in the ack'd state.
get '/raise/:id' => require_login sub {
    my $tmp = Purple::Alerts->new();
    my $out = $tmp->raiseEvent( params->{ 'id' } );
    return ( redirect '/' );
};

# Retrieve all events as JSON, invoked by AJAX for the web-ui.
get '/events' require_login => sub {
    my $tmp = Purple::Alerts->new();
    my $out = $tmp->getEvents();
    return to_json($out);
};

# Add a new event.
post '/events' => sub {
    my $data = request()->body();
    my $json = from_json($data);

    if ( ref $json eq "ARRAY" )
    {
        foreach my $obj ( @{ $json } )
        {
            # The source IP of the submitting-client.
            $obj->{ 'source' } = request()->address();

            my $e = Purple::Alerts->new();
            $e->addEvent( %{ $obj } );
        }
    }
    else
    {
        # Just a hash - single alert

        # The source IP of the submitting-client.
        $json->{ 'source' } = request()->address();

        my $e = Purple::Alerts->new();
        $e->addEvent( %{ $json } );
    }
    return "OK";
};

# All other route are 404.
any qr{.*} => sub {
    status 'not_found';
    "The path " . encode_entities(request->path) . " was not found";
};


1;
