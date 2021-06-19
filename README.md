# zwave-js-server-docker

A minimal docker container for [zwave-js-server](https://github.com/zwave-js/zwave-js-server/). This container provides a usable zwave-js-server and nothing else. The zwave-js-server is a websocket application that hosts the [Z-Wave JS](https://github.com/zwave-js/node-zwave-js) driver software.

For a more functional application that also provides the zwave-js-server, it is recommended to use [zwavejs2mqtt](https://github.com/zwave-js/zwavejs2mqtt/) instead.

## Docker Configuration

Z-Wave JS (the driver) stores information about the Z-Wave network in a set of cache files. When the server restarts, the driver loads the network information from the cache. Without this information the network will not be fully usable right away. Therefore it is very important that the cache files are persisted between container restarts.

### Run with a volume mount

```
# Create a persistent volume for the driver cache
docker volume create zjs-storage

# starts the server and uses the persistent volume
docker run -d -p 3000:3000 --name=zjs -v zjs-storage:/cache -e NETWORK_KEY="17DFB0C1BED4CABFF54E4B5375E257B3" --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" kpine/zwave-js-server:latest
```

### Run with a bind mount

```
# starts the server and uses the cache folder
docker run -d -p 3000:3000 --name=zjs -v "$PWD/cache:/cache" -e NETWORK_KEY="17DFB0C1BED4CABFF54E4B5375E257B3" --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" kpine/zwave-js-server:latest
```

### Docker Compose

Docker Compose is the easiest way to maintain a container configuration.

Minimal `docker-compose.yaml` file:

```yaml
services:
  zjs:
    container_name: zjs
    image: kpine/zwave-js-server:latest
    restart: unless-stopped
    environment:
      NETWORK_KEY: "17DFB0C1BED4CABFF54E4B5375E257B3"
    devices:
      - '/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave'
    volumes:
      - ./cache:/cache
    ports:
      - '3000:3000'
```

### Environment variables:

- `NETWORK_KEY`: The Z-Wave network key in hex string (0-9A-F) format with exactly 32 hex characters. This is a required value and the container will not start if left undefined.
- `LOGTOFILE`: Set this to `true` to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver to log to a file. Leave undefined to use the driver's default setting.
- `LOGFILENAME`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log filename (only used when `LOGTOFILE` is `true`). The default is `/logs/zwave_%DATE%.log`. Note that the driver will automatically rotate the logfiles using a date based scheme.
- `LOGLEVEL`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver loglevel. Leave undefined to use the driver's default setting.
- `USB_PATH`: The device path of the Z-Wave USB controller. Defaults to `/dev/zwave`. The controller device path can be mapped from the host as `/dev/zwave` instead as an alternative to using this variable.

### Directories:

- `/cache` - The driver [cache directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). A volume or bind mount should be mapped to this directory to persist the network information between container restarts.
- `/cache/config` - The driver [device configuration priority directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). Used to load your custom device configuration files. The directory is automatically created if `/cache` is a named volume, otherwise it must be created manually or mapped as a volume/bind mount.
- `/logs` - When logging to file is enabled, this is the directory where the driver log file is written to.

### Ports:

- `3000` - The zwave-js-server websocket port. External applications, such as Home Assistant, must be able to connect to this port.

## Hints

### Network Key
A simple way to generate a random network key is with the following command:
```
$ < /dev/urandom tr -dc A-F0-9 | head -c32 ; echo
8387D66323E8209C58B0C317FD1F4251
```

### USB Path

Instead of using the `USB_PATH` environment variable, map the device path to the default `/dev/zwave`.

### Device Configuration Fileis

Use the `/cache/config` directory to test new device config files or make modifications to existing ones. The files located in this directory will supplement or override the embedded devicie config database. The driver logs will indicate which file was loaded:

```
2021-06-19T06:19:18.506Z CNTRLR   [Node 007] Embedded device config loaded
```
```
2021-06-19T06:21:43.793Z CNTRLR   [Node 007] User-provided device config loaded
```