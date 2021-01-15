FROM node:15-alpine as node

FROM node as src

ARG PROJECT=zwave-js/zwave-js-server
ARG REVISION=master

RUN apk add --no-cache \
      curl \
      unzip

WORKDIR /src

RUN curl -sSL "https://github.com/${PROJECT}/tarball/${REVISION}" \
  | tar --strip-components=1 -xzv


FROM node as base

# Build tools required to install nodeserial
RUN apk add --no-cache --virtual .build-deps \
      build-base \
      gcc \
      linux-headers \
      python3

WORKDIR /app

COPY --from=src /src/package*.json /src/tsconfig.json ./
RUN npm install --production

# Build tools no longer needed
RUN apk del .build-deps


FROM base as build

WORKDIR /app

RUN npm install
COPY --from=src /src ./
RUN npm run build


FROM build as notest

WORKDIR /app

RUN npm cache clean --force
RUN rm -rf dist/test


FROM base as production

WORKDIR /app

COPY --from=notest /app/dist ./dist/
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
