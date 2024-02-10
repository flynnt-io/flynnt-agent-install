#!/bin/bash
## inspect_args

## --- use sudo if we are not already root ---
##SUDO=sudo
##if [ $(id -u) -eq 0 ]; then
##    SUDO=
##fi

isRoot() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "As we make changes to the system, you need to run this script as root"
		exit 1
	fi
}

isRoot

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
        echo "Authentication did not work :( Please try again"
        exit
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
add_node_request=$(curl -w "%{http_code}\n" -s -X POST -H "Content-Type: application/json" -H "Authorization: $token" -d "{\"nodeName\":\"$nodename\"}" "$API_ENDPOINT/cluster/${clustername}/node")
if [[ ${add_node_request: -3} != "200" ]]; then
  echo "Encountered error while adding node to the cluster: "
  echo "$add_node_request"
  exit
fi

## next, download the node config
curlResult=$(curl -w "%{http_code}\n" -s -X GET -H "Content-Type: application/json" -H "Authorization: $token" "$API_ENDPOINT/cluster/$clustername/node/$nodename/config")
if [[ ${curlResult: -3} != "200" ]]; then
  echo "Encountered error while getting node config: "
  echo "$curlResult"
  exit
fi
## TODO: curlResult still has the statuscode attached at the end and is no real json. We don't care for now
wireguardConfig=$(echo "$curlResult" | grep -oP '"wireguard":\s*\K".*?"')
wireguardConfig=${wireguardConfig:1:-1}
k3sConfig=$(echo "$curlResult" | grep -oP '"k3s":\s*\K".*?"')
k3sConfig=${k3sConfig:1:-1}
k8sVersion=$(echo "$curlResult" | grep -oP '"k8sVersion":\s*\K".*?"')
k8sVersion=${k8sVersion:1:-1}

echo "We will now install the node..."
# install wireguard
echo "Installing wireguard... (Step 1/2)"
install_wireguard "$wireguardConfig"

# install k3s
echo "Installing k3s... (Step 2/2)"
install_k3s "$k3sConfig" "$k8sVersion"

echo "Node successfully installed. Done!"

