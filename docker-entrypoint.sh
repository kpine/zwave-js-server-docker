#!/bin/sh
set -e

if [ "x$1" = "x" ]; then
  if [ ! -c "$USB_PATH" ]; then
    echo "USB path \"$USB_PATH\" does not exist or is not a character device"
    exit 1
  fi

  if [ -z "$NETWORK_KEY" ]; then
    echo "A network key is required"
    exit 1
  fi

  set -- zwave-server --config options.js "$USB_PATH"
elif [ "$1" = "server" ]; then
  shift
  set -- zwave-server "$@"
elif [ "$1" = "client" ]; then
  shift
  set -- zwave-client "$@"
fi

echo "Executing command:" "$@"
exec "$@"
