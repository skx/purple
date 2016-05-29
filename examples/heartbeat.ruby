#!/usr/bin/ruby
#
# Send a heartbeat alert, via Ruby.
#
# This is slightly different from the Perl-version in that we have to
# setup SSL explicitly.
#
# Steve
# --
#

require 'getoptlong'
require 'json'
require 'net/http'
require "net/https"

#
#  Default variables
#
dest     = "http://alert.example.com/events";
hostname = `hostname`.chomp!
clear    = false


#
#  Allow `--clear` to be used.
#
#  Allow URL/hostname to be changed.
#
opts = GetoptLong.new(
  [ '--hostname', '-h', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--url', '-u', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--clear', '-c', GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when '--url'
      dest = arg
    when '--clear'
      clear = true
    when '--hostname'
      hostname = arg
  end
end



#
#  The data we send
#
data = Hash.new

data['detail']  = "<p><tt>#{hostname}</tt> might be down!</p>"
data['id']      = "heartbeat.once";
data['raise']   = "+5m";
data['raise']   = "clear" if ( clear )
data['source']  = hostname
data['subject'] = "The heartbeat wasn't sent for #{hostname}"


# The URL we hit
uri  = URI(dest)

# The HTTP-object.
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true if ( dest =~ /^https/)

# The request
req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})

# Ensure the request-body has our JSON-payload
req.body = data.to_json

# Make the request
res = http.request(req)

# If successful all is OK
if res.is_a?(Net::HTTPSuccess)
  exit(0)
else

  # show the error
  puts res.body
  exit(1)
end
puts "response #{res.body}"
