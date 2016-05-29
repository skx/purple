# Purple

Purple is an event/alert manager which allows central collection and distribution of "alerts".

In short purple allows tracking the state of a number of pending alerts, raising them on demand.  For example a trivial `heartbeat` alert might be implemented by sending a message every minute:

* "Raise an alert if you don't hear from me in 5 minutes".

If all is well this message will be sent once a minute, and no alert is raised.  If the remote host stops sending that regular heartbeat message then a notification will be generated 5 minutes after the final one was received.




## About Alerts

Alerts are submitted by making a HTTP POST-request to the purple-server, with a JSON-body.

When a new POST request is received it will be transformed into an alert, which will be saved in the database.  This alert might be a new one, or it might contain an update of an existing alert.

Alerts have three states:

* Pending.
   * An alert will raise at some point in the future.
* Raised.
   * If an alert is raised notifications will be sent out every **minute** to inform your sysadmin(s).
* Cleared
   * Alerts which are cleared have previously been raised and closed manually, alerts in the cleared-state are reaped over time.


## Architecture

The purple-server presents a HTTP server which accepts incoming alert-submissions, as well as providing a simple user-interface to list the various raised, pending, or cleared alerts.

In addition to the core-server there is a second process which constantly scans the database (i.e. SQLite-file) to handle the state-transitions and raising of alerts.


* The purple-server received alerts.
   * It stores those incoming alerts into the database.
   * It also presents a web interface to the alert-events.
* The alerter reads that database to send out notifications.
   * If an alert is in the `cleared` state it is removed.
   * If an alert is in the `pending` state, and the raise-time has passed it is notified, and moved the `raised` state.
   * If an alert is in the `raised` state, and a notification was made more than a minute ago it is re-notified.


## Submissions

Submissions are expected to be JSON-encoded POST payloads, sent
to the http://1.2.3.4:port/events end-point.  Expected fields are:

|Field Name | Purpose                                                   |
|-----------|-----------------------------------------------------------|
|id         | Name of the alert                                         |
|subject    | Human-readable description of the alert-event.            |
|detail     | Human-readable (expanded) description of the alert-event. |
|raise      | When this alert should be raised.                         |

To handle uniqueness alerts are keyed upon the user-submitted `id` field, along with the source IP from which the submission was received.

As an example the following is a heartbeat alert.  Five minutes after the last update sent by this we'll receive an alert-notification:


     {
       "id"      : "heartbeat"
       "subject" : "The heartbeat wasn't sent for deagol.lan",
       "detail"  : "<p>This indicates that <tt>deagol.lan</tt> might be down!</p>",
       "raise"   : "+5m",
     }

Before the `5m` timeout has been reached the alert will be in the `pending` state, after that period has passed the alert will be moved into the `raised` state.

As you might expect the `raise` field is pretty significant.  Expected values are:

|`raise`| Purpose                                                 |
|-------|---------------------------------------------------------|
|`12345`| Raise at the given number of seconds past the epoch.    |
| `+5m` | Raise in 5 minutes.                                     |
| `+5h` | Raise in 5 hours.                                       |
| `now` | Raise immediately.                                      |
|`clear`| Clear the alert immediately.                            |


## Notifications

There is no built-in facility for sending text-messages, sending pushover notifications, or similar.  Instead the default alerting behaviour is to simply dump the details of the raised/re-raised alert to the console.

It is assumed you will have your own local facility for sending the alerts, and to implement it you just need to override the `notify` subroutine in the `lib/Alerts/Notifier/Local.pm` module.  The alerter will use that module/method if present, to generate the notifications.  Beyond that the alerter handles the state-transitions as you would expect:

* Select all alerts which have a raise-time of "now".
    * Send the notification.
    * Change the state to "raised".

* Select all alerts which are in state raised.
   * Re-notify if it has been over a minute since the last notification.

* Delete all alerts in a cleared state.


## Installation

Before you begin you'll almost certainly want to edit `lib/Alerts/Notifier/Local.pm` to ensure your alerts are sent _somewhere_ useful.

* Ensure that the web-UI & submission service is launched, and restarted on failure, by executing `./run`.
   * There is a sample systemd unit-file located in `examples/`.
* Configure Apache/nginx to proxy https://alert.example.com/ to `localhost:5151`.
* Ensure that the `./bin/alerter` daemon is launched, and restarted on failure.
   * There is a sample systemd unit-file located in `examples/`.



Steve
--
