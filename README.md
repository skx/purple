# Purple

Purple is an alert manager which allows the centralised collection and distribution of "alerts".

For example a trivial heartbeat-style alert might be implemented by sending a message every minute with a body containing:

* "Raise an alert if you don't hear from me in 5 minutes".




## About Alerts

Alerts are submitted by making a HTTP POST-request to the purple-server, with a JSON-payload of a [number of fields](ALERTS.md).

When a new POST request is received it will be transformed into an alert:

* If the alert is new it will be saved into the database.
* If the alert has been previously seen, then the fields of that existing alert will be updated.
     * This is possible because alerts are uniquely identified by a combination of the submitted `id` field and the source IP address from which it was received.

Alerts have several states:

* Pending.
   * An alert will raise at some point in the future.
* Raised.
   * A raised alert will trigger a notification every **minute** to inform your sysadmin(s).
* Acknowledged
   * An alert in the acknowledged state will not re-notify.
* Cleared
   * Alerts which are cleared have previously been raised but have now cleared.
   * Alerts in the cleared-state are reaped over time.


## Architecture

The purple-server presents a HTTP server which accepts incoming alert-submissions, as well as providing a simple web-based user-interface to list the various raised, pending, or cleared alerts.

In addition to the core-server there is a second process which constantly scans the database (i.e. SQLite-file) to handle the state-transitions and raising of alerts.

* The purple-server handles incoming HTTP-requests.
   * It stores incoming alerts in an SQLite database.
   * It also presents a web interface to the alert-events.
* The alerter reads that database to send out notifications.
   * If an alert is in the `acknowledged` state it is ignored.
   * If an alert is in the `cleared` state it is removed from the database.
   * If an alert is in the `pending` state and the notification time has passed it is moved into the `raised` state, and a notification is generated.
   * If an alert is in the `raised` state, and a notification was made more than a minute ago another notification is generated.
   * Finally if an alert has a `raise` time in the future then it is reset to be `pending`, allowing heartbeat-style alerts to auto-clear.


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

It is assumed you will have your own local preferred mechanism for sending the alerts, be it SMS, PushOver, email, or something else.  To implement your notification method you'll need to override the `notify` subroutine in the `lib/Purple/Alert/Notifier/Local.pm` module, using the sample code as examples.

The following samples are available:

* Send email - [Local.pm.email](https://github.com/skx/purple/blob/master/lib/Purple/Alert/Notifier/Local.pm.email)
    * With escalation - [Local.pm.escalate](https://github.com/skx/purple/blob/master/lib/Purple/Alert/Notifier/Local.pm.escalate)
* Send a pushover event - [Local.pm.pushover](https://github.com/skx/purple/blob/master/lib/Purple/Alert/Notifier/Local.pm.pushover)

The `bin/purple-alerter` script handles the state-transitions as you would expect:

* Select all alerts which have a raise-time of "now".
    * Change the state to "`raised`".
    * Send the a notification for each alert-event.
* Select all alerts which are in state `raised`.
   * Re-notify if it has been over a minute since the last notification.
* Delete all alerts in a `cleared` state.
   * Clear all alerts which have a `raise` in the future.


## Installation

Please see the [installation file](INSTALL.md).



Steve
--
