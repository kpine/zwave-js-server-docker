#!/usr/bin/env bash

[[ -z $REGISTRY ]] && { echo "ERROR: REGISTRY is not set"; exit 1; };
[[ -z $ZWAVE_JS_VERSION ]] && { echo "ERROR: ZWAVE_JS_VERSION is not set"; exit 1; };
[[ -z $ZWAVE_JS_SERVER_VERSION ]] && { echo "ERROR: ZWAVE_JS_SERVER_VERSION is not set"; exit 1; };

earthly --push +all \
  --BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --REGISTRY="${REGISTRY}" \
  --ZWAVE_JS_SERVER_VERSION="${ZWAVE_JS_SERVER_VERSION}" \
  --ZWAVE_JS_VERSION="${ZWAVE_JS_VERSION}"
