#!/usr/bin/perl -w
#
# Simple example of a heartbeat-alert, run this in a cron-job
# every minute.
#
# If your server dies then five minutes later an alert will be
# generated.
#
# Steve
# --
#


use strict;
use warnings;

use Getopt::Long;
use JSON;
use LWP::UserAgent;


#
#  Default options
#
my %CONFIG;

# Our hostname
$CONFIG{'hostname'} = `hostname`;
chomp($CONFIG{'hostname'});

# The location to send the alert to.
$CONFIG{'url'} = "http://alert.example.com/events";


exit if (
        !GetOptions(
                    "clear", \$CONFIG{ 'clear' },
                    "hostname=s", \$CONFIG{'hostname'},
                    "url=s", \$CONFIG{'url'},
        ) );



#
#  The object we'll send
#
my %data;

$data{ 'id' }      = "heartbeat.once";
$data{ 'source' }  = $CONFIG{'hostname'};
$data{ 'raise' }   = "+5m";
$data{ 'raise' }   = "clear" if ($CONFIG{'clear'});
$data{ 'subject' } = "The heartbeat wasn't sent for $CONFIG{'hostname'}",
$data{ 'detail' }  =   "<p><tt>$CONFIG{'hostname'}</tt> might be down!</p>";


#
#  Convert the data to JSON.
#
my $json = to_json( \%data );

#
#  Populate a new HTTP POST request with this body.
#
my $req  = HTTP::Request->new( 'POST', $CONFIG{'url'} );
$req->header( 'Content-Type' => 'application/json' );
$req->content($json);

#
# Now make the request
#
my $lwp = LWP::UserAgent->new;
my $res = $lwp->request($req);


#
#  Success?  Then exit.
#
exit 0 if ( $res->is_success() );

#
#  Show the error
#
print "Failed to send heartbeat: " . $res->status_line() . "\n";
exit(1);
