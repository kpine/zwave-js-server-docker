FROM alpine:3.15 as base

WORKDIR /app

FROM base as builder

# Build tools required to install serialport, a zwave-js dependency
RUN apk add --no-cache \
      g++ \
      git \
      linux-headers \
      make \
      nodejs \
      npm \
      python3

RUN npm config set \
      fetch-retries 5 \
      fetch-retry-mintimeout 100000 \
      fetch-retry-maxtimeout 600000 \
      cache-min 360

ARG ZWAVE_JS_VERSION=latest
ARG ZWAVE_JS_SERVER_VERSION=latest
ARG ZWAVE_JS_PACKAGE=zwave-js@${ZWAVE_JS_VERSION}
ARG ZWAVE_JS_SERVER_PACKAGE=@zwave-js/server@${ZWAVE_JS_SERVER_VERSION}
ARG NPM_INSTALL_EXTRA_FLAGS=

# Prebuilt binaries for node serialport and Alpine are broken, so we
# rebuild from source:
#   https://github.com/serialport/node-serialport/issues/2438
RUN npm install \
      ${NPM_INSTALL_EXTRA_FLAGS} \
      ${ZWAVE_JS_SERVER_PACKAGE} \
      ${ZWAVE_JS_PACKAGE} \
 && npm rebuild --build-from-source @serialport/bindings-cpp

FROM base as app

RUN apk add --no-cache \
      jq \
      nodejs

RUN mkdir -p /cache/config /cache/db /logs

ENV NODE_ENV=production
ENV PATH=/app/node_modules/.bin:$PATH
ENV USB_PATH=/dev/zwave
ENV LOGFILENAME=/logs/zwave_%DATE%.log
ENV ZWAVEJS_EXTERNAL_CONFIG=/cache/db

COPY --from=builder /app/ ./
COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME /cache
EXPOSE 3000
ENTRYPOINT ["docker-entrypoint.sh"]
