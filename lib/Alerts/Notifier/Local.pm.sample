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
#  Notifier - in this case we just send an email to `root` (unqualified).
#
sub notify
{
    my ( $self, $id, $reason ) = (@_);

    # Get the alert-data
    my $tmp   = Alerts->new();
    my $event = $tmp->getEvent($id);

    # Build up a subject
    my $subject = "$reason: [$event->{'id'}] - $event->{'subject'}";

    # Send an email to root.
    open( SENDMAIL, "|/usr/lib/sendmail -t" )
        or return;

    print SENDMAIL <<EOF;
To: root
From: root
Subject: $subject


$event->{'detail'}

EOF

    close( SENDMAIL )

}


1;
