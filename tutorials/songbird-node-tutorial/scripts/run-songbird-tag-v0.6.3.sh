#!/bin/bash

# Ensure you give script permission to execute with `chmod +x run-songbird.sh`

nohup $HOME/flare/build/flare --network-id=songbird \
  --bootstrap-ips="$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' https://songbird.flare.network/ext/info | jq -r ".result.ip")" \
  --bootstrap-ids="$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' -H 'content-type:application/json;' https://songbird.flare.network/ext/info | jq -r ".result.nodeID")" \
  --http-host=0.0.0.0 > /dev/null 2>&1 &
  
echo $! > pid.txt
printf "Songbird node launched | PID: $! \n"