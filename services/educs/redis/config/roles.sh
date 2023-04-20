#!/bin/bash
# Usage: ./roles.sh

urls=$(kubectl get pods -n educs -l app.kubernetes.io/name=redis -o jsonpath='{range.items[*]}{.status.podIP} ')
command="kubectl -n educs exec -it redis-0 -- redis-cli --cluster create --cluster-replicas 1 "

for url in $urls
do
    command+=$url":6379 "
done

echo "Executing command: " $command
$command
