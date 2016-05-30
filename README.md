# Purple

Purple is an event/alert manager which allows central collection and distribution of "alerts".  In short purple allows tracking the state of a number of alerts, raising them on demand.  For example a trivial `heartbeat` alert might be implemented by sending a message every minute:

* "Raise an alert if you don't hear from me in 5 minutes".

If a client-machine sends this message every 60 seconds (or even more frequently!) all is OK.  When the messages cease an alert will be raised five minutes later.



## About Alerts

Alerts are submitted by making a HTTP POST-request to the purple-server, with a JSON-payload of a [number of fields](#submissions).

When a new POST request is received it will be transformed into an alert, which will be saved in the database if it is new, if it is an alert which has previously been seen then the existing alert-object will be updated.

Alerts have three states:

* Pending.
   * An alert will raise at some point in the future.
* Raised.
   * If an alert is raised notifications will be sent out every **minute** to inform your sysadmin(s).
* Cleared
   * Alerts which are cleared have previously been raised and closed manually, alerts in the cleared-state are reaped over time.

To handle uniqueness alerts are keyed upon the user-submitted `id` field, along with the source IP from which the submission was received.  This allows you to send updates from multiple hosts named `heartbeat` without any confusion, for example.


## Architecture

The purple-server presents a HTTP server which accepts incoming alert-submissions, as well as providing a simple web-based user-interface to list the various raised, pending, or cleared alerts.

In addition to the core-server there is a second process which constantly scans the database (i.e. SQLite-file) to handle the state-transitions and raising of alerts.

* The purple-server handles incoming HTTP-requests.
   * It stores incoming alerts in an SQLite database.
   * It also presents a web interface to the alert-events.
* The alerter reads that database to send out notifications.
   * If an alert is in the `cleared` state it is removed.
   * If an alert is in the `pending` state, it is moved into the `raised` state, and a notification is generated.
   * If an alert is in the `raised` state, and a notification was made more than a minute ago another notification is generated.


### Differences between MauveAlert

If you're familiar with mauvealert, which inspired this project, then the following are the largest differences:

* Alerts in purple are submitted via HTTP-POST requests containing JSON-bodies, rather than `protobuf` bodies over a UDP transport.
* There is no policy-routing.
   * All alerts are notified in the same way, rather than being conditional on the alert, the time of day, etc.
* In purple alerts have no urgency settings, they're all treated at the same priority-level.
* The AJAX/web interface in purple is prettier.
* purple has no notion of supression.
* In purple all raised alerts are re-notified every 60 seconds, rather than having any back-off.
   * You can make alerts one-shot by adding a `.once` suffix to the ID.
   * They'll stay in the web user-interface but the notification will only fire once.
* In purple you must write your own notification-class to deliver alerts.
   * Although we do include an example which generates emails.
* In purple you cannot notify when an alert has cleared.


## Submissions

Submissions are expected to be JSON-encoded POST payloads, sent
to the http://1.2.3.4:port/events end-point.  Expected fields are:

|Field Name | Purpose                                                   |
|-----------|-----------------------------------------------------------|
|id         | Name of the alert                                         |
|subject    | Human-readable description of the alert-event.            |
|detail     | Human-readable (expanded) description of the alert-event. |
|raise      | When this alert should be raised.                         |


As an example the following is a heartbeat alert.  Five minutes after the last update sent by this we'll receive an alert-notification:


     {
       "id"      : "heartbeat"
       "subject" : "The heartbeat wasn't sent for deagol.lan",
       "detail"  : "<p>This indicates that <tt>deagol.lan</tt> might be down!</p>",
       "raise"   : "+5m",
     }

Before the `5m` timeout has been reached the alert will be in the `pending` state and will be visible in the web user-interface.  Five minutes after the last submission the alert will be moved into the `raised` state.

As you might expect the `raise` field is pretty significant.  Permissable values include:

|`raise`| Purpose                                                 |
|-------|---------------------------------------------------------|
|`12345`| Raise at the given number of seconds past the epoch.    |
| `+5m` | Raise in 5 minutes.                                     |
| `+5h` | Raise in 5 hours.                                       |
| `now` | Raise immediately.                                      |
|`clear`| Clear the alert immediately.                            |

> **NOTE**: Submitting an update which misses any of the expected fields is an error.



## Notifications

There is no built-in facility for sending text-messages, sending pushover notifications, or similar.  Instead the default alerting behaviour is to simply dump the details of the raised/re-raised alert to the console.

It is assumed you will have your own local preferred mechanism for sending the alerts, be it SMS, PushOver, email, or something else.  To implement your notification method you'll need to override the `notify` subroutine in the `lib/Alerts/Notifier/Local.pm` module, using [the sample Local.pm modules](https://github.com/skx/purple/blob/master/lib/Alerts/Notifier/) as examples.  The `bin/alerter` script will invoke that method if it is present, if it is not then alerts in the `raised` state will merely be dumped ot the console.

The `bin/alert` script handles the state-transitions as you would expect:

* Select all alerts which have a raise-time of "now".
    * Send the a notification for each alert-event.
    * Change the state to "`raised`".
* Select all alerts which are in state `raised`.
   * Re-notify if it has been over a minute since the last notification.
* Delete all alerts in a cleared state.


## Installation

Before you begin you'll want to populate the notification-module `lib/Alerts/Notifier/Local.pm`, to ensure your alerts are actually sent somewhere.  Otherwise installation should be straight-forward:


* Ensure that the web-UI & submission service is launched, and restarted on failure, by executing `./run`.
   * There is a sample `systemd` unit-file located in `examples/`.
* Configure Apache/nginx to proxy https://alert.example.com/ to `localhost:5151`, which is the default port the service operates upon.
* Ensure that the `./bin/alerter` daemon is launched, and restarted on failure.
   * There is a sample systemd unit-file located in `examples/`.



Steve
--
