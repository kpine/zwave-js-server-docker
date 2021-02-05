FROM alpine:3.13 as base

RUN apk add --no-cache \
      nodejs \
      npm

FROM base as builder

# Specify PACKAGE_NAME and PACKAGE_VERSION to install various versions,
# including from Github.
ARG PACKAGE_NAME=@zwave-js/server
ARG PACKAGE_VERSION=@1.0.0-beta.4

# Build tools required to install nodeserial, a zwave-js dependency
RUN apk add --no-cache \
      g++ \
      git \
      linux-headers \
      make \
      python3

WORKDIR /app

RUN npm install ${PACKAGE_NAME}${PACKAGE_VERSION}

FROM base as app

RUN apk add --no-cache \
      jq

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/ ./
RUN npm prune --production

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME ["/cache", "/logs"]
EXPOSE 3000

ENV PATH=/app/node_modules/.bin:$PATH

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
