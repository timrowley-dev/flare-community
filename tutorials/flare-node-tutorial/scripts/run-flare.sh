#!/bin/bash

# Ensure you give script permission to execute with `chmod +x run-flare.sh`

nohup $HOME/go-flare/avalanchego/build/avalanchego --network-id=flare \
  --bootstrap-ips="$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' https://flare.flare.network/ext/info | jq -r ".result.ip")" \
  --bootstrap-ids="$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' -H 'content-type:application/json;' https://flare.flare.network/ext/info | jq -r ".result.nodeID")" \ 
  --http-host=0.0.0.0 > /dev/null 2>&1 &
  
echo $! > pid.txt
printf "Flare node launched | PID: $! \n"