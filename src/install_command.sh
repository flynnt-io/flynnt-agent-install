#!/bin/bash
## inspect_args

# shellcheck disable=SC2154
nodename=${args[--nodename]}
clustername=${args[--clustername]}
API_KEY=${API_KEY:-}
API_ENDPOINT=${API_ENDPOINT:-}

echo "Will try to join this server as '$nodename' to the cluster '$clustername'"
# authenticate and grab config

if [ -z "$API_KEY" ]
then
  ## curl -X POST -H "Content-Type: application/json" https://api.app.flynnt.io/device/token
  ## {"deviceCode":"xyz","userCode":"abc","verificationUrl":"https://app.flynnt.io/device/ABC"}

  ## from here https://stackoverflow.com/questions/55607925/extract-json-value-with-sed
  ## POST https://api.app.flynnt.io/device/token to create a token request
  curlResult=$(curl -s -X POST -H "Content-Type: application/json" --silent "$API_ENDPOINT/device/token")
  userCode=$(echo "$curlResult" | grep -oP '"userCode":\s*\K[^\s,]*(?=\s*[,}])')
  userCode=${userCode:1:-1}
  deviceCode=$(echo "$curlResult" | grep -oP '"deviceCode":\s*\K[^\s,]*(?=\s*[,}])')
  deviceCode=${deviceCode:1:-1}
  verificationUrl=$(echo "$curlResult" | grep -oP '"verificationUrl":\s*\K[^\s,]*(?=\s*[,}])')
  verificationUrl=${verificationUrl:1:-1}
  echo "Click here to authenticate yourself: $verificationUrl"

  ## https://unix.stackexchange.com/questions/644343/bash-while-loop-stop-after-a-successful-curl-request
  ## curl -X GET -H "Content-Type: application/json" https://api.app.flynnt.io/device/token?deviceCode=fQsrBJtwGtaBXGuIX8c6QOYkuTQT6i9PUtZ7FX7R03Nsx7p3teesiGKLk1QEnBvj
  ## {"token":"xyz"}

  ## Todo: Add max 5 minute timeout
  ## Todo: We need to listen to return codes, not only the payload that is returned to detect errors/denied in the flow
  while true
  do
    curlResult=$(curl -s -X GET --show-error -H "Content-Type: application/json" "$API_ENDPOINT/device/token?deviceCode=$deviceCode")
    if [ -z "$curlResult" ]
    then
      ## printf '%s' "."
      true
    else
      token=$(echo "$curlResult" | grep -oP '"token":\s*\K[^\s,]*(?=\s*[,}])')
      token=${token:1:-1}
      if [ -z "$token" ]
      then
        die "Authentication did not work. Please try again."
      else
        echo "Successfully authenticated."
        break
      fi
    fi
    sleep 5
  done
else
  echo "API_KEY was set. We will use that for authentication"
  token="Bearer $API_KEY"
fi
##echo "We made it out of the loop with a token: $token"

## create node if it does not exist yet
api_request POST "/cluster/$clustername/node" "{\"nodeName\":\"$nodename\"}"
if [[ $api_status != 2?? ]]; then
  die "Encountered error while adding node to the cluster (HTTP $api_status): $api_body"
fi

api_request GET "/cluster/$clustername/node/$nodename/config"
if [[ $api_status != 2?? ]]; then
  die "Encountered error while getting node config (HTTP $api_status): $api_body"
fi
wireguardConfig=$(json_string_field wireguard "$api_body")
k3sConfig=$(json_string_field k3s "$api_body")
k8sVersion=$(json_string_field k8sVersion "$api_body")

echo "We will now install the node..."
# install wireguard
echo "Installing wireguard... (Step 1/2)"
install_wireguard "$wireguardConfig"

# install k3s
echo "Installing k3s... (Step 2/2)"
install_k3s "$k3sConfig" "$k8sVersion"

echo "Node successfully installed. Done!"

