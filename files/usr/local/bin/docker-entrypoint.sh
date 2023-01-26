#!/bin/sh
set -e

if [ -z "$1" ]; then
  if [ ! -c "${USB_PATH}" ]; then
    echo "USB path \"${USB_PATH}\" does not exist or is not a valid serial device"
    exit 1
  fi

  if [ -n "${NETWORK_KEY}" ]; then
    echo "NETWORK_KEY has been removed, use S0_LEGACY_KEY instead"
    exit 1
  fi

  set -- zwave-server "${USB_PATH}" --config options.js

  if [ "${ENABLE_DNS_SD}" != "true" ]; then
    set -- "$@" --disable-dns-sd
  fi

  echo "Starting zwave-server:" "$@"
elif [ "$1" = "server" ]; then
  shift
  set -- zwave-server "$@"
elif [ "$1" = "client" ]; then
  shift
  set -- zwave-client "$@"
elif [ "$1" = "flash" ]; then
  if [ ! -c "${USB_PATH}" ]; then
    echo "USB path \"${USB_PATH}\" does not exist or is not a valid serial device"
    exit 1
  fi

  set -- flash "${USB_PATH}" "$@"
  echo "Flashing controller firmware:" "$@"
fi

exec "$@"
