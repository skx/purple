
=head1 NAME

Alerts::Server - Dancer Web-UI.

=head1 DESCRIPTION

This module implements our HTTP-interface, which serves two purposes:

* Handle the submission of JSON-encoded events

* Handle the web-based user interface.


=cut

package Alerts::Server;

use strict;
use warnings;

use Dancer;
use Dancer::Plugin::Auth::Extensible;


set show_errors => 1;
use Alerts;


# Show the web-interface.
get '/' => require_login sub {
    send_file 'index.html';
};


# Show the login-page.
get '/login' => sub {
    send_file 'login.html';
};


# Clear an event which is in the raised/pending state.
get '/clear/:id' => require_login sub {
    my $tmp = Alerts->new();
    my $out = $tmp->clearEvent( params->{ 'id' } );
    return ( redirect '/' );
};


# Retrieve all events as JSON, invoked by AJAX for the web-ui.
get '/events' => sub {
    my $tmp = Alerts->new();
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

            my $e = Alerts->new();
            $e->addEvent( %{ $obj } );
        }
    }
    else
    {
        # Just a hash - single alert

        # The source IP of the submitting-client.
        $json->{ 'source' } = request()->address();

        my $e = Alerts->new();
        $e->addEvent( %{ $json } );
    }
    return "OK";
};

# All other route are 404.
any qr{.*} => sub {
    status 'not_found';
    "The path " . request->path . " was not found";
};


1;
