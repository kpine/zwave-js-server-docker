FROM node:15-alpine as builder

# Build tools required to install nodeserial, a zwave-js dependency
RUN apk add --no-cache \
      g++ \
      linux-headers \
      make \
      python

WORKDIR /app

RUN npm install --production @zwave-js/server

FROM node:15-alpine as app

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/ ./
RUN npm prune --production

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

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
