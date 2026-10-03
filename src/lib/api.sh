#!/bin/bash

# Sets api_status and api_body. Sends $token as the Authorization header if set.
# shellcheck disable=SC2034
api_request() {
  local method=$1 path=$2 data=${3:-} response_file
  response_file=$(mktemp)
  local curl_args=(-sS -X "$method" -H "Content-Type: application/json" -o "$response_file" -w '%{http_code}')
  if [[ -n ${token:-} ]]; then
    curl_args+=(-H "Authorization: $token")
  fi
  if [[ -n $data ]]; then
    curl_args+=(-d "$data")
  fi
  api_status=$(curl "${curl_args[@]}" "$API_ENDPOINT$path") || api_status=000
  api_body=$(<"$response_file")
  rm -f "$response_file"
}

# Only handles string values without escaped quotes, which is all the API returns.
json_string_field() {
  local key=$1 json=$2
  printf '%s' "$json" | grep -oP "\"$key\":\s*\"\K[^\"]*" || true
}
