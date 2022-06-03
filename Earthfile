VERSION 0.6

FROM alpine:3.16

ARG ZWAVE_JS_VERSION=latest
ARG ZWAVE_JS_SERVER_VERSION=latest

WORKDIR /app

RUN apk add --no-cache \
      nodejs

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
        g++ \
        git \
        linux-headers \
        make \
        npm \
        python3

  RUN npm config set \
        fetch-retries 5 \
        fetch-retry-mintimeout 100000 \
        fetch-retry-maxtimeout 600000

  ARG ZWAVE_JS_PACKAGE=zwave-js@$ZWAVE_JS_VERSION
  ARG ZWAVE_JS_SERVER_PACKAGE=@zwave-js/server@$ZWAVE_JS_SERVER_VERSION
  ARG NPM_INSTALL_EXTRA_FLAGS

  # Prebuilt binaries for node serialport and Alpine are broken, so we
  # rebuild from source:
  #   https://github.com/serialport/node-serialport/issues/2438
  RUN npm install \
        $NPM_INSTALL_EXTRA_FLAGS \
        $ZWAVE_JS_SERVER_PACKAGE \
        $ZWAVE_JS_PACKAGE \
    && npm rebuild --prefer-offline --build-from-source @serialport/bindings-cpp

  SAVE ARTIFACT /app

docker:
  COPY +build/app .
  COPY --dir files/* /

  RUN mkdir -p \
        /cache/config \
        /cache/db \
        /fw \
        /logs

  RUN apk add --no-cache \
        minicom \
   && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
        lrzsz

  ARG EARTHLY_GIT_SHORT_HASH
  ARG VERSION="$ZWAVE_JS_SERVER_VERSION-$ZWAVE_JS_VERSION"
  ARG BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  ENV BUILD_VERSION="$VERSION-$EARTHLY_GIT_SHORT_HASH"
  ENV ENABLE_DNS_SD=false
  ENV LOGFILENAME=/logs/zwave_%DATE%.log
  ENV NODE_ENV=production
  ENV PATH=/app/node_modules/.bin:$PATH
  ENV USB_PATH=/dev/zwave
  ENV ZWAVEJS_EXTERNAL_CONFIG=/cache/db

  LABEL org.opencontainers.image.created=$BUILD_DATE
  LABEL org.opencontainers.image.description="A standalone Z-Wave JS Server"
  LABEL org.opencontainers.image.revision=$EARTHLY_GIT_SHORT_HASH
  LABEL org.opencontainers.image.source="https://github.com/kpine/zwave-js-server-docker"
  LABEL org.opencontainers.image.title="Z-Wave JS Server"
  LABEL org.opencontainers.image.version=$VERSION

  VOLUME /cache
  EXPOSE 3000
  ENTRYPOINT ["docker-entrypoint.sh"]

docker-test:
  FROM +docker
  ARG TAG_EXTRA=1
  ARG EARTHLY_GIT_SHORT_HASH
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  IF [ "$TAG_EXTRA" = "1" ]
    SAVE IMAGE --push $REGISTRY/$REPOSITORY:rc-$EARTHLY_GIT_SHORT_HASH
  END
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:rc

docker-release:
  FROM +docker
  ARG TAG_EXTRA=1
  ARG EARTHLY_GIT_SHORT_HASH
  ARG TAG="$ZWAVE_JS_SERVER_VERSION-$ZWAVE_JS_VERSION"
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  IF [ "$TAG_EXTRA" = "1" ]
    SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG-$EARTHLY_GIT_SHORT_HASH
  END
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:latest
