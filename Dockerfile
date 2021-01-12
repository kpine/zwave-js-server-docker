FROM node:15-alpine as node

RUN apk add --no-cache --virtual .build-deps \
      build-base \
      curl \
      gcc \
      linux-headers \
      python3 \
      unzip

FROM node AS builder

ARG PROJECT=zwave-js/zwave-js-server
ARG REVISION=master

WORKDIR /src

RUN curl -sSL -o src.zip "https://github.com/${PROJECT}/archive/${REVISION}.zip" \
 && unzip -q src.zip

WORKDIR /app

RUN cp /src/zwave-js-server-*/package*.json /src/zwave-js-server-*/tsconfig.json ./ \
 && npm install \
 && cp -r /src/zwave-js-server-*/src ./ \
 && npm run build

FROM node as app

ENV NODE_ENV=production

WORKDIR /app
RUN mkdir dist

COPY --from=builder /app/package*.json ./

RUN npm install --only=production
RUN apk del .build-deps

COPY --from=builder /app/dist ./dist
COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME /cache
EXPOSE 3000

# Generate a network key:
#   tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
ENV NETWORK_KEY=
ENV USB_PATH=/dev/zwave

ENTRYPOINT ["docker-entrypoint.sh"]
