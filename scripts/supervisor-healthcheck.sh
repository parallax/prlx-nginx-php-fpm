#!/bin/bash

python healthcheck.py | grep -qv "'statename': 'FATAL'"
if (($(echo $?) != "0" )); then
	supervisorctl start all
	echo "Starting All Services"
fi