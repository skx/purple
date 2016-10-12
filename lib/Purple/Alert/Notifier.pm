
=head1 NAME

Purple::Alert::Notifier - Handle raising notifications.

=head1 SYNOPSIS

      use strict;
      use warnings;

      use Purple::Alert::Notifier;

      my $tmp = Alerts->new( notify => \&my_alerter );

      $tmp->reap();
      $tmp->notifyNew();

=cut

=head1 DESCRIPTION

This module contains code for actually issuing notifications, based upon
the state of our database.

In brief there are three actions you can take:

=over 8

=item Reaping old alerts, so that they don't clutter our database and our web-UI.

=item Clearing alerts when they are re-submitted with raise-times in the future.

=item Raising a notification for any alert which has now reached the time it should be fired.

=item Re-raising a notification for any alert which is in the raised-state, and which was last notified in excess of 60 seconds ago.

=back

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut



package Purple::Alert::Notifier;

use strict;
use warnings;

use Singleton::DBI;


=head2 new

Constructor.

We expect a DBI handle, and a call-back function to be passed to our constructor.

=cut

sub new
{
    my ( $class, %params ) = @_;
    my $self = {};
    bless( $self, $class );
    $self->{ 'dbi' }    = Singleton::DBI->instance();
    $self->{ 'notify' } = $params{ 'notify' };

    # User can specify delay.
    $self->{ 'delay' } = 59;
    $self->{ 'delay' } = $params{ 'delay' } if ( $params{ 'delay' } );

    # We'll `print` output if verbose is set
    $self->{ 'verbose' } = 1 if ( $params{ 'verbose' } );
    return $self;
}


=head2 reap

Remove old/obsolete events from the database.

=cut

sub reap
{
    my ($self) = (@_);

    my $clear =
      $self->{ 'dbi' }
      ->prepare("DELETE FROM events WHERE status='cleared' OR raise_at < 1");
    $clear->execute();
    $clear->finish();
}


=head2 timewarp

If an alert is in a raised state, but the `raise_at` time is in the
future then we can clear it.

This allows heartbeat alerts to auto-clear when they return.

=cut

sub timewarp
{
    my ($self) = (@_);

    my $dbh = $self->{ 'dbi' };

    my $sql = $dbh->prepare(
        "UPDATE events SET status='pending' WHERE ( raise_at > strftime('%s','now') ) AND raise_at > 0"
    );
    $sql->execute();
    $sql->finish();
}



=head2 notifyNew

If there are any alerts which should be raised for the first time,
then change their state to `raised` (rather than `pending` which they
would begin in, and issue the alert.

Alerts are notified by invoking the callback submitted in our constructor.

=cut

sub notifyNew
{

    my ($self) = (@_);

    my $dbh = $self->{ 'dbi' };

    my $sql = $dbh->prepare(
        "SELECT i FROM events WHERE status='pending' AND ( raise_at < strftime('%s','now') ) AND raise_at > 0"
    );
    $sql->execute();
    my $id;
    $sql->bind_columns( undef, \$id );
    while ( $sql->fetch() )
    {
        # Show what we're doing, if we're running verbosely.
        $self->{ 'verbose' } && print "raising for alert ID: $id\n";

        # Raise the alert, via the call-back function.
        $self->{ 'notify' }( $id, "raise" );

        # Bump the raised_at time, and update the status
        my $update =
          $dbh->prepare("UPDATE events SET notified_at=?,status=? WHERE i=?");
        my $now = scalar( time() );
        $update->execute( $now, "raised", $id );
        $update->finish();
    }
}


=head2 reNotify

If any event is in the raised state, and it was last notified more than
a minute ago, then notify anew.

The only parameter is the period between re-raising previously-raised alerts,
which defaults to 60 seconds if not specified.

Alerts are notified by invoking the callback submitted in our constructor.

=cut

sub reNotify
{
    my ( $self, $delay ) = (@_);

    my $dbh = $self->{ 'dbi' };

    # Default delay
    $delay = $self->{ 'delay' } if ( !$delay );

    # If delay is not a number then default it, again.
    $delay = $self->{ 'delay' } unless ( $delay =~ /^([0-9]+)$/ );

    #
    # Look for raised alerts we need to re-notify.
    #
    my $sql = $dbh->prepare(
        "SELECT i FROM events WHERE status='raised' AND ( abs( notified_at - strftime('%s','now') ) >= $delay )"
    );
    $sql->execute();
    my $id;
    $sql->bind_columns( undef, \$id );

    while ( $sql->fetch() )
    {

        # Show what we're doing, if we're running verbosely.
        $self->{ 'verbose' } && print "reraising for alert ID: $id\n";

        # Re-raise the alert, via the call-back function.
        $self->{ 'notify' }( $id, "reraise" );

        # Bump the raised_at time
        my $update = $dbh->prepare("UPDATE events SET notified_at=? WHERE i=?");
        my $now    = scalar( time() );
        $update->execute( $now, $id );
        $update->finish();

    }
    $sql->finish();
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
