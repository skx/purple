#
#  Alter this module to provide your own notification system.
#
#  You might send SMS, use PushOver.net, or similar.
#
#

package Alerts::Notifier::Local;


#
# Constructor.
#
sub new
{
    my ( $class, %params ) = @_;
    my $self = {};
    bless( $self, $class );
    return $self;
}


#
#  Notifier.
#
sub notify
{
    my ( $self, $id, $reason ) = (@_);

    print "LOCAL NOTIFIER\n";

    my $tmp   = Alerts->new();
    my $event = $tmp->getEvent($id);

    if ( $reason =~ /^raise$/ )
    {
        print "Raising event $id\n";
    }
    elsif ( $reason =~ /^reraise$/i )
    {
        print "Re-raising event $id\n";
    }
    else
    {
        print "Unknown reason for notifying event $id - $reason\n";
    }


    #
    #  Dump to console.
    #
    print "Subject: [$event->{'id'}] $event->{'subject'}\n";
    print "Source : $event->{'source'}\n";
    print "\n\t$event->{'detail'}\n\n";

}


1;
