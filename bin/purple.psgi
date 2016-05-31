#!/usr/bin/perl -Ilib/ -I../lib/

use strict;
use warnings;

use Dancer;
use Purple::Server;
use Plack::Builder;



#
# Gain access to an instance of our application
#
my $app = sub {
    my $env = shift;
    my $request = Dancer::Request->new( env => $env );
    Dancer->dance($request);
};


#
# Load the application, with the appropriate middleware.
#
# We want to ensure we get the real IP if behind a proxy.
#
builder
{
    #
    # If the remote address is 127.0.0.1 load the reverse proxy
    # detecting module to get the real IP.
    #
    # Do this first.
    #
    enable_if {$_[0]->{ REMOTE_ADDR } eq '127.0.0.1'}
    "Plack::Middleware::ReverseProxy";

    #
    # Return the application
    #
    $app;
};
