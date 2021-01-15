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

VOLUME /cache
EXPOSE 3000

# Generate a network key:
#   tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
ENV NETWORK_KEY=
ENV USB_PATH=/dev/zwave

ENTRYPOINT ["docker-entrypoint.sh"]
