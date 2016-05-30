# Installation

To get started you'll need to install the dependencies:

	  apt-get install libdancer-perl libdancer-plugin-auth-extensible-perl \
            twiggy libplack-middleware-reverseproxy-perl libplack-perl     \
            libtime-modules-perl libtime-parsedate-perl

Once installed you need to consider how events will be delivered.  By default
the alerting script (`bin/alerter`) will just dump messages to the console.

To implement your custom notification system you'll want to populate the
file `lib/lib/Alerts/Notifier/Local.pm`, and you can draw inspiration from
the two provided samples:

* `Local.pm.email`
   * Sends alerts via email.
* `Local.pm.pushover`
   * POSTs messages to a mobile phone via [pushover](http://pushover.net/)
   * NOTE: You need to update that script to contain your credentials.



# Username / Password

The web-UI is protected by username/password.  To add new users, or change
passwords please see the file `config.yml`.


# Launching

You need to ensure that two services are running, constantly, and are restarted
on failure:

        # The event-receiver and web-ui
        ./run

        # The alerter
        ./bin/alerter [-v]

Both of these can be launched under the control of systemd, via the files provided
beneath `examples/`.


# Problems?

If you have a problem please do report an issue.


Steve
-- 

