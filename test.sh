#!/usr/bin/env bash

[[ -z $ZWAVE_JS_VERSION ]] && { echo "ERROR: ZWAVE_JS_VERSION is not set"; exit 1; };
[[ -z $ZWAVE_JS_SERVER_VERSION ]] && { echo "ERROR: ZWAVE_JS_SERVER_VERSION is not set"; exit 1; };

earthly +test \
  --ZWAVE_JS_VERSION="${ZWAVE_JS_VERSION}" \
  --ZWAVE_JS_SERVER_VERSION="${ZWAVE_JS_SERVER_VERSION}"
