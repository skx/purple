
=head1 NAME

Alerts - Handle our alerts.

=head1 SYNOPSIS

      use strict;
      use warnings;

      use Alerts;

      my $tmp = Alerts->new();
      my $out = $tmp->getEvents();

      return to_json($out);

=cut

=head1 DESCRIPTION

This module contains code for working with an alert-event, or
collection of the same.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut

use strict;
use warnings;

package Alerts;

use Singleton::DBI;
use Time::ParseDate;


=head2 new

This is the constructor, no arguments are required or expected.

=cut

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}


=head2 addEvent

Create a new event, from the supplied parameters.

Parameters include:

=over 8

=item C<id>
The ID of the event (e.g. "hearbeat", or "unread-email")

=item C<subject>
The human-readable subject for the alert.

=item C<detail>
The human-readable details about the alert.

=item C<raise>
The time to raise the event (e.g. "5m", "4h", "now", or "clear" to
actually clear the event post-raise).

=back

=cut

sub addEvent
{
    my ( $self, %params ) = (@_);

    my $dbh     = Singleton::DBI->instance();
    my $id      = $params{ 'id' } || die "No 'id' field!";
    my $src     = $params{ 'source' } || die "No 'source' field!";
    my $subject = $params{ 'subject' } || die "No 'subject' field!";
    my $detail  = $params{ 'detail' } || die "No 'detail' field!";
    my $raise   = $params{ 'raise' } || die "No 'raise' field!";

    #
    #  If the raise time is relative update the units
    #
    if ( $raise =~ /^\+\s*([0-9]+)\s*([hmsd])$/i )
    {
        my $units;
        $units = "days"  if ( $2 eq "d" );
        $units = "hours" if ( $2 eq "h" );
        $units = "mins"  if ( $2 eq "m" );
        $units = "secs"  if ( $2 eq "s" );

        # Update units
        $raise = "+ $1 $units";

        # Parse to EPOCH-TIme
        $raise = parsedate( $raise, NOW => time() );

    }
    elsif ( $raise =~ /^now$/i )
    {
        # NOW.
        $raise = time();
    }
    elsif ( $raise =~ /^clear$/i )
    {
        # NOW.
        $raise = -1;
    }

    my $sql = $dbh->prepare(
        "INSERT OR REPLACE INTO Events( i, id, source, subject, detail, raise_at ) VALUES( ( SELECT i FROM Events WHERE id=? AND source=?) , ?, ?, ? , ?, ? )"
    );
    $sql->execute( $id, $src, $id, $src, $subject, $detail, $raise );
    $sql->finish();

    #
    #  The ID of the event we've updated.
    #
    $id = $dbh->last_insert_id( undef, undef, undef, undef );
    return ($id);
}

=head2 getEvent

Get the single, specified, event by ID.

=cut

sub getEvent
{
    my ( $self, $id ) = (@_);

    my $dbh   = Singleton::DBI->instance();
    my $fetch = $dbh->prepare("SELECT * FROM events WHERE i=?");
    $fetch->execute($id);
    my $result = $fetch->fetchall_arrayref( {} );

    # We'll only have one result.
    my @r = @$result;
    my $x = $r[0];

    return ($x);
}


=head2 getEvents

Return all the events we know about, from our database.

=cut

sub getEvents
{
    my ( $self, %params ) = (@_);

    my $dbh = Singleton::DBI->instance();

    my $fetch = $dbh->prepare("SELECT * FROM events");
    $fetch->execute();
    my $result = $fetch->fetchall_arrayref( {} );

    return ($result);
}

=head2 clearEvent

Clear the event with the given identifier.

=cut

sub clearEvent
{
    my ( $self, $id ) = (@_);

    my $dbh = Singleton::DBI->instance();

    my $fetch = $dbh->prepare("UPDATE events SET status='cleared' WHERE i=?");
    $fetch->execute($id);
    $fetch->finish();

}

1;


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version,
or

b) the Perl "Artistic License".

=cut

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut
