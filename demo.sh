#!/usr/bin/env bash

cd `dirname $0`

function run() {
    eval "$0 $INSTANCE $1"
}

case "$1" in
    start)
      ./start.sh
    ;;
    stop)
      ./stop.sh
    ;;
    restart)
      ./stop.sh && \
      ./start.sh
    ;;
    *)
      echo $"Commands:"
      echo $" demo start"
      echo $" demo stop"
      echo $" demo restart"
esac
