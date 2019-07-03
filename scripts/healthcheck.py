#!/usr/bin/python

import xmlrpclib
server = xmlrpclib.Server('http://localhost:9001/RPC2')

print(server.supervisor.getAllProcessInfo())