VERSION 0.6

FROM alpine:3.13

ARG ZWAVE_JS_VERSION=latest
ARG ZWAVE_JS_PACKAGE=zwave-js@$ZWAVE_JS_VERSION
ARG ZWAVE_JS_SERVER_VERSION=latest
ARG ZWAVE_JS_SERVER_PACKAGE=@zwave-js/server@$ZWAVE_JS_SERVER_VERSION
ARG NPM_INSTALL_EXTRA_FLAGS

WORKDIR /app

all:
  BUILD \
    --platform=linux/amd64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm64 \
    +docker-release

test:
  BUILD \
    --platform=linux/amd64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm64 \
    +docker-test


build:
  RUN apk add --no-cache \
        nodejs \
        g++ \
        git \
        linux-headers \
        make \
        npm \
        python3

  # node serialport fails to install without a newer npm
  RUN npm install npm@latest -g

  RUN npm install \
        $NPM_INSTALL_EXTRA_FLAGS \
        $ZWAVE_JS_SERVER_PACKAGE \
        $ZWAVE_JS_PACKAGE

  SAVE ARTIFACT /app /app

docker:
  COPY +build/app /app
  COPY docker-entrypoint.sh /usr/local/bin/
  COPY options.js /app

  RUN apk add --no-cache \
        nodejs \
        jq

  RUN mkdir -p /cache/config /cache/db /logs

  ENV NODE_ENV=production
  ENV PATH=/app/node_modules/.bin:$PATH
  ENV USB_PATH=/dev/zwave
  ENV LOGFILENAME=/logs/zwave_%DATE%.log
  ENV ZWAVEJS_EXTERNAL_CONFIG=/cache/db

  VOLUME /cache
  EXPOSE 3000
  ENTRYPOINT ["docker-entrypoint.sh"]

docker-test:
  FROM +docker
  ARG EARTHLY_TARGET_TAG_DOCKER
  ARG TAG="test-$EARTHLY_TARGET_TAG_DOCKER"
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG

docker-release:
  FROM +docker
  ARG EARTHLY_TARGET_TAG_DOCKER
  ARG TAG="$EARTHLY_TARGET_TAG_DOCKER"
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG $REGISTRY/$REPOSITORY:latest