# Alerts

To generate an alert you first need to pick an ID.

IDs are human readable labels for the alerts, and they don't need to be globally unique.  Instead alerts are keyed upon the ID __and__ the source IP address from which they were received.

Example alert IDs might be `disk-full`, `heartbeat`, `unread-mail-foo.com` and `unread-mail-bar.com`.

## Raising an Alert

To raise an alert send a JSON message with the `raise` field set to `now`:

     {
       "id"      : "morning"
       "subject" : "Time to get up!",
       "detail"  : "<p>The time is 5am, you should be awake now.</p>",
       "raise"   : "now",
     }

This alert will be immediately raised, and the notifications will repeat until the alert is cleared - either via a clear-submission, or via the Web user-interface.


## Clearing an Alert

To clear an existing alert send a JSON message with the `raise` field set to `clear`:

     {
       "id"      : "morning"
       "subject" : "Time to get up",
       "detail"  : "<p>The time is 5am, you should be awake now.</p>",
       "raise"   : "clear",
     }

**NOTE**: You are forced to submit `detail` and `subject` fields, even though you're clearing the existing alert.


## Self-Clearing Alerts

If you're writing an alert to tell you that a website is down you can bundle up the previous sections as you would expect:

    v = Hash.new()
    v['subject'] = "http://example.com/ is down"
    v['detail']  = "<p>The fetch failed.</p>"
    v['id']      = "web-example.com"

    if  site_alive
       v['raise'] = 'clear'
    else
       v['raise'] = 'now'
    end

With code like this you can send an alert which will either have the raise field set to either `now` or `clear`.  Each update will change the state appropriately.


## Heartbeat Alerts

Heartbeat alerts are well-documented, but instead of sending simple "raise" or "clear" events you instead set a relative time in your `raise` field.

For example you could send, every minute, a submission like this:


     {
       "id"      : "heartbeat"
       "subject" : "example.my.flat is down.",
       "detail"  : "<p>The heartbeat wasn't received for example.my.flat.</p>",
       "raise"   : "+3m",
       }

Assuming that this update is sent every 60 seconds the alert will raise three minutes after the last update.  That would require the host was down for three minutes, or that three updates were lost en route.


# Notifications

By default notifications are repeated for each alert in the raised-state.  These notifications repeat every 60 seconds.

You can configure different back-off times if you wish, via your own `Purple::Alerts::Notifier::Local` module.  As an example of special handling the supplied samples only alert **once** if an ID ends in `.once` suffix.

This behaviour is useful if you're using an external service to deliver your alert-messages.  For example I use the [pushover](http://pushover.net/) service, and there is a facility there to repeat the notifications until they are read with the mobile phone application.  If I raise the alert once there, the phone will beep every minute - so there is no need to repeatedly send the message.
