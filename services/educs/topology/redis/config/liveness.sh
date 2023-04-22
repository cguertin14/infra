#!/bin/sh

pingResponse="$(redis-cli -h localhost ping | head -n1 | awk '{print $1;}')"
if [ "$?" -eq "124" ]; then
	echo "PING timed out"
	exit 1
fi

if [ "$pingResponse" != "PONG"] && [ "$pingResponse" != "LOADING" ] && [ "$pingResponse" != "MASTERDOWN" ]; then
	echo "$pingResponse"
	exit 1
fi