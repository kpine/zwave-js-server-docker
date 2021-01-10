# TODO: replace with slim or alpine
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

WORKDIR /app

# TODO: allow revision
# wget https://github.com/zwave-js/zwave-js-server/archive/{sha}.zip
RUN curl -sSL -O "https://github.com/zwave-js/zwave-js-server/archive/master.zip" \
 && unzip -q master.zip \
 && mv zwave-js-server-master/* . \
 && rm master.zip

RUN npm install

RUN apk del .build-deps

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME /cache
EXPOSE 3000

# Generate a network key:
# tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
ENV NETWORK_KEY=
ENV USB_PATH=/dev/zwave

ENTRYPOINT ["docker-entrypoint.sh"]
