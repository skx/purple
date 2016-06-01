#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 4;

BEGIN
{

    #
    #  Our modules
    #
    use_ok( "Singleton::DBI", "Loaded module" );
    use_ok( "Purple::Server", "Loaded module" );
    use_ok( "Purple::Alerts", "Loaded module" );
    use_ok( "Purple::Alert::Notifier", "Loaded module" );
}
