

deploy:
	rsync -vazr . root@www.steve.org.uk:/etc/service/alert.steve.org.uk/
