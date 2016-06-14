function update_alerts()
{
    $.getJSON( "/events" , function( data ) {
        var h = {};
        h['raised'] = 0
        h['pending'] = 0
        h['acknowledged'] = 0

        $.each( data, function( key, val ) {

            // Bump the count of this type of alerts, for the title.
            var status = val['status'];
            h[status] = h[status]+1

            // This is horrid - we want to show either "will raise at",
            // "last notified at", or nothing depending on the type.
            if ( status == "raised" ) {

                var d = Math.round( val['notified_at'] * 1000)
                d = parseFloat(d);
                d = new Date( d  );

                // id | source | subject | last notified | action
                var t = "<tr><td>" + val['i'] + "</td>";
                t += "<td>" + val['source'] + "</td>";
                t += "<td class=\"click\">" + val['subject'] + "</td>";
                t += "<td>" + d  + "</td>";
                t += "<td><a href=\"/acknowledge/" + (val['i']) + "\">ack</a>"
                t += " <a href=\"/clear/" + (val['i']) + "\">clear</a>"
                t += "</td>"

                // Add the alert
                $("#" + val['status'] + "_alerts").find('tbody').append(t)

                // Add the details.
                $("#" + val['status'] + "_alerts").find('tbody')
                    .append("<tr style=\"display:none;\"><td></td><td colspan=\"4\"><p>" + val['detail'] + "</p></td></tr>")
            }
            if ( status == "acknowledged" ) {

                // id | source | subject | actions
                var t = "<tr><td>" + val['i'] + "</td>";
                t += "<td>" + val['source'] + "</td>";
                t += "<td class=\"click\">" + val['subject'] + "</td>";
                t += "<td><a href=\"/raise/" + (val['i']) + "\">raise</a> <a href=\"/clear/" + (val['i']) + "\">clear</a></td>"

                // Add the alert
                $("#" + val['status'] + "_alerts").find('tbody').append(t)

                // Add the details.
                $("#" + val['status'] + "_alerts").find('tbody')
                    .append("<tr style=\"display:none;\"><td></td><td colspan=\"4\"><p>" + val['detail'] + "</p></td></tr>")

            }
            if ( status == "pending" ) {

                var d = Math.round( val['raise_at'] * 1000)
                d = parseFloat(d);
                d = new Date( d  );

                // id | source | subject | last notified | action
                var t = "<tr><td>" + val['i'] + "</td>";
                t += "<td>" + val['source'] + "</td>";
                t += "<td class=\"click\">" + val['subject'] + "</td>";
                t += "<td>" + d  + "</td>";
                t += "<td><a href=\"/clear/" + (val['i']) + "\">clear</a></td>"

                // Add the alert
                $("#" + val['status'] + "_alerts").find('tbody').append(t)

                // Add the details.
                $("#" + val['status'] + "_alerts").find('tbody')
                    .append("<tr style=\"display:none;\"><td></td><td colspan=\"4\"><p>" + val['detail'] + "</p></td></tr>")
            }


            // Set the title.
            document.title = "Alerts [" + h['raised'] + "/" + h['acknowledged'] + "/" + h['pending'] + "]";

        });
    });
}
