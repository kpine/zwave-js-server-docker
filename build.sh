#!/usr/bin/env bash

[[ -z ${ZWAVE_JS_VERSION} ]] && { echo "ERROR: ZWAVE_JS_VERSION is not set"; exit 1; };
[[ -z ${ZWAVE_JS_SERVER_VERSION} ]] && { echo "ERROR: ZWAVE_JS_SERVER_VERSION is not set"; exit 1; };

[[ -z $1 ]] && { echo "A target reference is required: build.sh +<target-name>"; exit 1; };

build_args=(
  --ZWAVE_JS_SERVER_VERSION="${ZWAVE_JS_SERVER_VERSION}"
  --ZWAVE_JS_VERSION="${ZWAVE_JS_VERSION}"
)

[[ -n ${REGISTRY} ]] && build_args+=(--REGISTRY="${REGISTRY}")
[[ -n ${REPOSITORY} ]] && build_args+=(--REPOSITORY="${REGISTRY}")

earthly "$1" "${build_args[@]}"
