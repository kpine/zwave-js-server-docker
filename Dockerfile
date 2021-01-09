# TODO: replace with slim or alpine
FROM node:15-buster-slim

RUN npm install -g typescript ts-node

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      unzip

WORKDIR /app

# TODO: allow revision
# wget https://github.com/zwave-js/zwave-js-server/archive/{sha}.zip
RUN curl -sSL -O "https://github.com/zwave-js/zwave-js-server/archive/master.zip" \
 && unzip -q master.zip \
 && mv zwave-js-server-master/* . \
 && rm master.zip

RUN npm install

RUN apt-get remove -y \
      curl \
      unzip \
 && rm -rf /var/lib/apt/lists/* \
 && (apt-get autoremove -y; apt-get autoclean -y)

COPY docker-entrypoint.sh /usr/local/bin/
COPY options.js .

VOLUME /cache
EXPOSE 3000

# Generate a network key:
# tr -dc '0-9A-F' </dev/urandom | fold -w 32 | head -n 1
ENV NETWORK_KEY=
ENV USB_PATH=/dev/zwave

ENTRYPOINT ["docker-entrypoint.sh"]
