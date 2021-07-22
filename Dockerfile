FROM alpine:3.13 as base

RUN apk add --no-cache \
      nodejs

FROM base as builder

# Build tools required to install serialport, a zwave-js dependency
RUN apk add --no-cache \
      g++ \
      git \
      linux-headers \
      make \
      npm \
      python3

RUN npm install npm@latest -g

WORKDIR /app

ARG ZWAVE_JS_PACKAGE=zwave-js@8.0.5
ARG ZWAVE_JS_SERVER_PACKAGE=@zwave-js/server@1.9.1

RUN npm install ${ZWAVE_JS_SERVER_PACKAGE} ${ZWAVE_JS_PACKAGE}

FROM base as app

RUN apk add --no-cache \
      jq

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/ ./
COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .
RUN mkdir -p /cache/config \
             /logs

VOLUME "/cache"
EXPOSE 3000

ENV PATH=/app/node_modules/.bin:$PATH

ENV USB_PATH=/dev/zwave
# Generate a network key (32-byte hex string):
#   < /dev/urandom tr -dc A-F0-9 | head -c32 ; echo
ENV NETWORK_KEY=
# true/false (default false)
ENV LOGTOFILE=
# error, warn, info, http, verbose, debug, silly (default debug)
ENV LOGLEVEL=
# when LOGTOFILE true, log to this file
ENV LOGFILENAME=/logs/zwave_%DATE%.log

ENTRYPOINT ["docker-entrypoint.sh"]
