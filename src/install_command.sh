#!/bin/bash
## inspect_args

# shellcheck disable=SC2154
nodename=${args[--nodename]}
clustername=${args[--clustername]}
API_KEY=${API_KEY:-}
API_ENDPOINT=${API_ENDPOINT:-}
token=""

echo "Will try to join this server as '$nodename' to the cluster '$clustername'"
# authenticate and grab config

if [ -z "$API_KEY" ]
then
  ## POST /device/token returns {"deviceCode":"...","userCode":"...","verificationUrl":"..."}
  api_request POST /device/token
  if [[ $api_status != 2?? ]]; then
    die "Could not start authentication (HTTP $api_status): $api_body"
  fi
  deviceCode=$(json_string_field deviceCode "$api_body")
  verificationUrl=$(json_string_field verificationUrl "$api_body")
  if [[ -z $deviceCode || -z $verificationUrl ]]; then
    die "Unexpected response when starting authentication: $api_body"
  fi
  echo "Click here to authenticate yourself: $verificationUrl"

  ## GET /device/token?deviceCode=... returns 400 while pending, 404 once the
  ## request expired or was denied, and 200 {"token":"..."} after approval.
  deadline=$((SECONDS + 300))
  while true
  do
    api_request GET "/device/token?deviceCode=$deviceCode"
    case $api_status in
      200)
        token=$(json_string_field token "$api_body")
        [[ -n $token ]] || die "Authentication did not work. Please try again."
        echo "Successfully authenticated."
        break
        ;;
      400)
        ;;
      404)
        die "The authentication request expired or was denied. Please try again."
        ;;
      *)
        die "Unexpected response while waiting for authentication (HTTP $api_status): $api_body"
        ;;
    esac
    if (( SECONDS >= deadline )); then
      die "Authentication timed out after 5 minutes. Please try again."
    fi
    sleep 5
  done
else
  echo "API_KEY was set. We will use that for authentication"
  token="Bearer $API_KEY"
fi

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

