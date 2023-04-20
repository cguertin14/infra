#!/bin/sh

pingResponse="$(redis-cli -h localhost ping)"
if [ "$?" -eq "124" ]; then
	echo "PING timed out"
	exit 1
fi

if [ "$pingResponse" != "PONG"]; then
	echo "$pingResponse"
	exit 1
fi