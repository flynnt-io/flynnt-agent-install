#!/bin/bash

echo ""
read -rp "Do you really want to remove this node from the cluster? [y/n]: " -e REMOVE
REMOVE=${REMOVE:-n}
if [[ $REMOVE == 'y' ]]; then
  remove_wireguard
  remove_k3s
else
  echo ""
  echo "Removal aborted!"
fi