
test:
	prove --shuffle t/

deploy:
	ssh s-purple@www.steve.org.uk 'git pull origin master'
	ssh root@www.steve.org.uk sv restart /etc/service/alert.steve.fi/

deps:
	apt-get install libdancer-perl libdancer-plugin-auth-extensible-perl twiggy libplack-middleware-reverseproxy-perl libplack-perl libtime-modules-perl libtime-parsedate-perl
