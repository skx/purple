
=head1 NAME

Singleton::DBI - Accessor for our (SQLite) database

=head1 SYNOPSIS

      use strict;
      use warnings;

      use Singleton::DBI;

      my $dbi = Singleton::DBI::instance();

      $dbi->do( "DELETE FROM `history` WHERE id<1976" );


=cut

=head1 DESCRIPTION

This module contains code for getting access to a database.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;

package Singleton::DBI;

use DBI;



my $_dbh = undef;



=head2 instance

Gain access to the single instance of our database connection.

=cut

sub instance
{
    my ($self) = (@_);

    $_dbh ||= $self->new();

    if ( !$_dbh->ping() )
    {
        $_dbh = $self->new();
    }

    return ($_dbh);
}


=head2 new

Create a new instance of this object.  This is only ever called once
since this object is used as a Singleton.

=cut

sub new
{

    my $file = "dbfile";

    my $found = 0;
    $found = 1 if ( -e $file );

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$file", "",
                            "" { sqlite_use_immediate_transaction => 1, } );


    my $sql = <<EOF;
CREATE TABLE events (
    i INTEGER PRIMARY KEY,
   id    text not null,
  source text not null,
  status char(10) DEFAULT 'pending',
 raise_at int,
 notified_at int,
 subject text not null,
 detail  text not null
);
EOF

    $dbh->do($sql) unless ($found);

    #
    #  Try to speedup.
    #
    $dbh->do("PRAGMA synchronous = OFF");
    $dbh->do("PRAGMA journal_mode = WAL");

    #
    #  Attempt to avoid locking issues, via a timeoout of two seconds.
    #
    $dbh->sqlite_busy_timeout( 1000 * 2 );

    return ($dbh);
}


1;
