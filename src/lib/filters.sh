#!/bin/bash

filter_root() {
  [[ $(id -u) -eq 0 ]] || echo "This script changes system configuration and must be run as root"
}
