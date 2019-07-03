#!/bin/bash

echo "Supervisor Healthcheck Running!"

while true
do
	python healthcheck.py | grep -qv "'statename': 'FATAL'"
	if (($(echo $?) != "0" )); then
		supervisorctl start all
		echo "Starting All Services"
	fi
	sleep 5
done
