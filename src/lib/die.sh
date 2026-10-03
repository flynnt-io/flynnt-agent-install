#!/bin/bash

die() {
  red "$*" >&2
  exit 1
}
