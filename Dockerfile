FROM node:15-alpine as base

RUN npm install -g typescript ts-node

FROM base as app

RUN apk add --no-cache --virtual .build-deps \
      build-base \
      curl \
      gcc \
      linux-headers \
      python3 \
      unzip

ARG PROJECT=zwave-js/zwave-js-server
ARG REVISION=master

WORKDIR /src

RUN curl -sSL -o src.zip "https://github.com/${PROJECT}/archive/${REVISION}.zip" \
 && unzip -q src.zip \
 && mkdir /app \
 && mv zwave-js-server-*/* /app

WORKDIR /app

RUN rm -rf /src \
 && npm install

RUN apk del .build-deps

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME /cache
EXPOSE 3000

# Generate a network key:
#   tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
ENV NETWORK_KEY=
ENV USB_PATH=/dev/zwave

ENTRYPOINT ["docker-entrypoint.sh"]
