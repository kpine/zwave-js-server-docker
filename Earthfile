VERSION 0.8

FROM alpine:3.22

WORKDIR /app

# renovate: datasource=repology depName=alpine_3_22/nodejs versioning=loose
ARG NODEJS_VERSION=22.23.2-r0
RUN apk add --no-cache \
      nodejs=$NODEJS_VERSION \
      tzdata

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
        npm

  RUN npm config set \
        fetch-retries 5 \
        fetch-retry-mintimeout 100000 \
        fetch-retry-maxtimeout 600000

  COPY package.json package-lock.json ./

  ARG NPM_INSTALL_EXTRA_FLAGS
  RUN npm ci --omit=dev $NPM_INSTALL_EXTRA_FLAGS

  # Optional overrides of the locked versions (e.g. "latest" for test builds)
  ARG ZWAVE_JS_VERSION
  ARG ZWAVE_JS_SERVER_VERSION
  RUN specs=""; \
      if [ -n "$ZWAVE_JS_VERSION" ]; then \
        specs="$specs zwave-js@$ZWAVE_JS_VERSION @zwave-js/flash@$ZWAVE_JS_VERSION"; \
      fi; \
      if [ -n "$ZWAVE_JS_SERVER_VERSION" ]; then \
        specs="$specs @zwave-js/server@$ZWAVE_JS_SERVER_VERSION"; \
      fi; \
      if [ -n "$specs" ]; then \
        npm install --omit=dev $NPM_INSTALL_EXTRA_FLAGS $specs; \
      fi

  SAVE ARTIFACT /app

docker:
  COPY +build/app .
  COPY --dir files/* /

  RUN mkdir -p \
        /cache/config \
        /cache/db \
        /logs

  RUN apk add --no-cache \
        tini

  ARG EARTH_GIT_SHORT_HASH
  # <server version>-<zwave-js version>, read from the installed packages
  ARG VERSION=$(node --print "['@zwave-js/server', 'zwave-js'].map((p) => require('/app/node_modules/' + p + '/package.json').version).join('-')")
  ARG BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  ENV BUILD_VERSION="$VERSION-$EARTH_GIT_SHORT_HASH"
  ENV ENABLE_DNS_SD=false
  ENV LOGFILENAME=/logs/zwavejs
  ENV NODE_ENV=production
  ENV PATH=/app/node_modules/.bin:$PATH
  ENV USB_PATH=/dev/zwave
  ENV ZWAVEJS_EXTERNAL_CONFIG=/cache/db

  LABEL org.opencontainers.image.created=$BUILD_DATE
  LABEL org.opencontainers.image.description="A standalone Z-Wave JS Server"
  LABEL org.opencontainers.image.revision=$EARTH_GIT_SHORT_HASH
  LABEL org.opencontainers.image.source="https://github.com/kpine/zwave-js-server-docker"
  LABEL org.opencontainers.image.title="Z-Wave JS Server"
  LABEL org.opencontainers.image.version=$VERSION

  VOLUME /cache
  EXPOSE 3000
  ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint.sh"]

docker-test:
  FROM +docker
  ARG TAG_EXTRA=1
  ARG EARTH_GIT_SHORT_HASH
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  IF [ "$TAG_EXTRA" = "1" ]
    SAVE IMAGE --push $REGISTRY/$REPOSITORY:rc-$EARTH_GIT_SHORT_HASH
  END
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:rc

docker-release:
  FROM +docker
  ARG TAG_EXTRA=1
  ARG EARTH_GIT_SHORT_HASH
  ARG TAG=$(node --print "['@zwave-js/server', 'zwave-js'].map((p) => require('/app/node_modules/' + p + '/package.json').version).join('-')")
  ARG REGISTRY=docker.io
  ARG REPOSITORY=kpine/zwave-js-server
  IF [ "$TAG_EXTRA" = "1" ]
    SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG-$EARTH_GIT_SHORT_HASH
  END
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:$TAG
  SAVE IMAGE --push $REGISTRY/$REPOSITORY:latest
