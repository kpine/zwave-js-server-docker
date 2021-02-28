# zwave-js-server-docker

A minimal docker container for [zwave-js-server](https://github.com/zwave-js/zwave-js-server/).

Sample `docker-compose.yaml`:

```
version: '3.8'

services:

  zjs:
    container_name: zjs
    image: kpine/zwave-js-server:latest
    restart: unless-stopped
    environment:
      NETWORK_KEY: "17DFB0C1BED4CABFF54E4B5375E257B3"
      LOGTOFILE: "true"
      TZ: "America/Los_Angeles"
    devices:
      - '/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave'
    volumes:
      - ./cache:/cache
      - ./logs:/logs
    ports:
      - '3000:3000'
```

Environment variables:
- `NETWORK_KEY`: The Z-Wave network key in hex string (0-9A-F) format. Must be exactly 32 hex characters and is a required value.
- `LOGTOFILE`: Set to `true` to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) node-zwave-js to log to a file. Optional, and the default is the node-zwave-js default.
- `LOGFILENAME`: Set to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the node-zwave-js logfile (when `LOGTOFILE` is `true`). The default is `/logs/zwave.log`. This is only relevant if `LOGTOFILE` is `true`.
- `LOGLEVEL`: Set to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the node-zwave-js loglevel. Optionals, and the default is the node-zwave-js default.

Volumes:
- `/cache` - The default volume where the node-zwave-js cache files are stored.
- `/logs` - The default volume where the node-zwave-js log file is stored.

Ports:
- `3000` - The default port that is exposed for the websocket connection.

A simple way to generate a network key is with the following command:
```
$ < /dev/urandom tr -dc A-F0-9 | head -c32 ; echo
8387D66323E8209C58B0C317FD1F4251
```
