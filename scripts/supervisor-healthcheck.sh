#!/bin/bash

python healthcheck.py | grep -qv "'statename': 'FATAL'"