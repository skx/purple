# Purple

Purple is an event/alert manager which allows central collection and distribution of "alerts".  In short purple allows tracking the state of a number of alerts, raising them on demand.  For example a trivial `heartbeat` alert might be implemented by sending a message every minute:

* "Raise an alert if you don't hear from me in 5 minutes".

If a client-machine sends this message every 60 seconds (or even more frequently!) all is OK.  When the messages cease an alert will be raised five minutes after the last successfully-received submission.



## About Alerts

Alerts are submitted by making a HTTP POST-request to the purple-server, with a JSON-payload of a [number of fields](ALERTS.md).

When a new POST request is received it will be transformed into an alert, which will be saved in the database if it is new.  If a submission relates to an alert which has previously been seen then that existing alert-object will be updated.

Alerts have three states:

* Pending.
   * An alert will raise at some point in the future.
* Raised.
   * If an alert is raised notifications will be sent out every **minute** to inform your sysadmin(s).
* Cleared
   * Alerts which are cleared have previously been raised but have now cleared.
   * Alerts in the cleared-state are reaped over time.

To handle uniqueness alerts are keyed upon the user-submitted `id` field, along with the source IP from which the submission was received.  This allows you to send updates from multiple hosts named `heartbeat` without any confusion, for example.


## Architecture

The purple-server presents a HTTP server which accepts incoming alert-submissions, as well as providing a simple web-based user-interface to list the various raised, pending, or cleared alerts.

In addition to the core-server there is a second process which constantly scans the database (i.e. SQLite-file) to handle the state-transitions and raising of alerts.

* The purple-server handles incoming HTTP-requests.
   * It stores incoming alerts in an SQLite database.
   * It also presents a web interface to the alert-events.
* The alerter reads that database to send out notifications.
   * If an alert is in the `cleared` state it is removed.
   * If an alert is in the `pending` state and the notification time has passed it is moved into the `raised` state, and a notification is generated.
   * If an alert is in the `raised` state, and a notification was made more than a minute ago another notification is generated.


## Alert Submissions

Submissions are expected to be JSON-encoded POST payloads, sent
to the http://1.2.3.4:port/events end-point.  The required fields are:

|Field Name | Purpose                                                   |
|-----------|-----------------------------------------------------------|
|id         | Name of the alert                                         |
|subject    | Human-readable description of the alert-event.            |
|detail     | Human-readable (expanded) description of the alert-event. |
|raise      | When this alert should be raised.                         |

Further details are available in the [alert guide](ALERTS.md).


## Notifications

There is no built-in facility for sending text-messages, sending pushover notifications, or similar.  Instead the default alerting behaviour is to simply dump the details of the raised and re-raised alerts to the console.

It is assumed you will have your own local preferred mechanism for sending the alerts, be it SMS, PushOver, email, or something else.  To implement your notification method you'll need to override the `notify` subroutine in the `lib/Purple/Alert/Notifier/Local.pm` module, using [the sample Local.pm modules](https://github.com/skx/purple/blob/master/lib/Purple/Alert/Notifier/) as examples.  The `bin/purple-alerter` script will invoke that method if it is present, if it is not then alerts in the `raised` state will merely be dumped ot the console.

The `bin/alert` script handles the state-transitions as you would expect:

* Select all alerts which have a raise-time of "now".
    * Change the state to "`raised`".
    * Send the a notification for each alert-event.
* Select all alerts which are in state `raised`.
   * Re-notify if it has been over a minute since the last notification.
* Delete all alerts in a cleared state.


## Installation

Please see the [installation file](INSTALL.md).



Steve
--
