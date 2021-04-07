FROM alpine:3.13 as base

RUN apk add --no-cache \
      nodejs \
      npm

FROM base as builder

ARG ZWAVE_JS_PACKAGE=zwave-js@7.1.1
ARG ZWAVE_JS_SERVER_PACKAGE=@zwave-js/server@1.4.0

# Build tools required to install nodeserial, a zwave-js dependency
RUN apk add --no-cache \
      g++ \
      git \
      linux-headers \
      make \
      python3

WORKDIR /app

RUN npm install ${ZWAVE_JS_SERVER_PACKAGE} ${ZWAVE_JS_PACKAGE}

FROM base as app

RUN apk add --no-cache \
      jq

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/ ./
COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME ["/cache", "/logs"]
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
ENV LOGFILENAME=/logs/zwave.log

ENTRYPOINT ["docker-entrypoint.sh"]
