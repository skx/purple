
package Alerts::Server;

use strict;
use warnings;

use Dancer;

set show_errors => 1;
use Alerts;

# Show web-interface.
get '/' => sub {
    send_file 'index.html';
};

# Clear an event.
get '/clear/:id' => sub {
    my $tmp = Alerts->new();
    my $out = $tmp->clearEvent( params->{ 'id' } );
    return ( redirect '/' );
};

# Get all events as JSON.
get '/events' => sub {
    my $tmp = Alerts->new();
    my $out = $tmp->getEvents();
    return to_json($out);
};

# Add a new event.
post '/events' => sub {
    my $data = request()->body();
    my $json = from_json($data);

    # The source IP of the submitting-client.
    $json->{'source'} = request()->address();

    my $e = Alerts->new();
    $e->addEvent( %{ $json } );

    return "OK";
};

# All other route are 404.
any qr{.*} => sub {
    status 'not_found';
    "The path " . request->path . " was not found";
};


1;
