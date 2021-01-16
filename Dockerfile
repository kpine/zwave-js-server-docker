FROM node:15-alpine

# Build tools required to install nodeserial, a zwave-js dependency
RUN apk add --no-cache --virtual .build-deps \
      build-base \
      gcc \
      linux-headers \
      python3

RUN npm install -g --production @zwave-js/server

# Build tools no longer needed
RUN apk del .build-deps

WORKDIR /app

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

ENV NODE_ENV=production

VOLUME ["/cache", "/logs"]
EXPOSE 3000

ENV USB_PATH=/dev/zwave
# Generate a network key:
#   tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
# 32-byte hex string
ENV NETWORK_KEY=
# true/false (default false)
ENV LOGTOFILE=
# error, warn, info, http, verbose, debug, silly (default debug)
ENV LOGLEVEL=
ENV LOGFILENAME=/logs/zwave.log

ENTRYPOINT ["docker-entrypoint.sh"]
