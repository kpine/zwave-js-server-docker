# zwave-js-server-docker

A minimal docker container for [zwave-js-server](https://github.com/zwave-js/zwave-js-server/). This container provides a usable zwave-js-server and nothing else. The zwave-js-server is a websocket application that hosts the [Z-Wave JS](https://github.com/zwave-js/node-zwave-js) driver software.

For a more functional application that also provides the zwave-js-server, it is recommended to use [zwavejs2mqtt](https://github.com/zwave-js/zwavejs2mqtt/) instead.

## Docker Configuration

Z-Wave JS (the driver) stores information about the Z-Wave network in a set of cache files. When the server restarts, the driver loads the network information from the cache. Without this information the network will not be fully usable right away. Therefore it is very important that the cache files are persisted between container restarts.

The `docker run` examples below use an environment file to provide all of the Z-Wave network keys.

```shell
$ cat .env
S2_ACCESS_CONTROL_KEY=7764841BC794A54442E324682A550CEF
S2_AUTHENTICATED_KEY=66EA86F088FFD6D7497E0B32BC0C8B99
S2_UNAUTHENTICATED_KEY=2FAB1A27E19AE9C7CC6D18ACEB90C357
S0_LEGACY_KEY=17DFB0C1BED4CABFF54E4B5375E257B3
```

### Run with a volume mount

```shell
# Create a persistent volume for the driver cache
$ docker volume create zjs-storage

# starts the server and uses the volume as the persistent cache directory
$ docker run -d -p 3000:3000 --name=zjs -v zjs-storage:/cache --env-file=.env --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" kpine/zwave-js-server:latest
```

### Run with a bind mount

```shell
# starts the server and uses a local folder as the persisent cache directory
$ docker run -d -p 3000:3000 --name=zjs -v "$PWD/cache:/cache" --env-file=.env --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" kpine/zwave-js-server:latest
```

### Docker Compose

Docker Compose is a simple way to maintain a container configuration.

Example of a minimal `docker-compose.yaml` file:

```yaml
services:
  zjs:
    container_name: zjs
    image: kpine/zwave-js-server:latest
    restart: unless-stopped
    environment:
      S2_ACCESS_CONTROL_KEY: "7764841BC794A54442E324682A550CEF"
      S2_AUTHENTICATED_KEY: "66EA86F088FFD6D7497E0B32BC0C8B99"
      S2_UNAUTHENTICATED_KEY: "2FAB1A27E19AE9C7CC6D18ACEB90C357"
      S0_LEGACY_KEY: "17DFB0C1BED4CABFF54E4B5375E257B3"
    devices:
      - '/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave'
    volumes:
      - ./cache:/cache
    ports:
      - '3000:3000'
```

### Environment variables

- `LOGTOFILE`: Set this to `true` to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver to log to a file.
- `LOGFILENAME`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log filename (only used when `LOGTOFILE` is `true`). The default is `/logs/zwave_%DATE%.log`. Note that the driver will automatically rotate the log files using a date based scheme.
- `LOGLEVEL`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log level.
- `S2_ACCESS_CONTROL_KEY`: The network key for the S2 Access Control security class.
- `S2_AUTHENTICATED_KEY`: The network key for the S2 Authenticated security class.
- `S2_UNAUTHENTICATED_KEY`: The network key for the S2 Unauthenticated security class.
- `S0_LEGACY_KEY`: The network key for the S0 (Legacy) security class. This replaces the deprecated `NETWORK_KEY` variable.
- `USB_PATH`: The device path of the Z-Wave USB controller. Defaults to `/dev/zwave`. Use of this variable is unnecessary if the controller device path is mapped from the host as `/dev/zwave`.

### Directories

- `/cache` - The driver [cache directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). A volume or bind mount should be mapped to this directory to persist the network information between container restarts.
- `/cache/config` - The driver [device configuration priority directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). Used to load your custom device configuration files. The directory is automatically created if `/cache` is a named volume, otherwise it must be created manually or mapped as a volume/bind mount.
- `/logs` - When logging to file is enabled, this is the directory where the driver log file is written to. Assign a volume or bind mount to this directory to access and save the log files outside of the container.

### Ports

- `3000` - The zwave-js-server websocket port. External applications, such as Home Assistant, must be able to connect to this port to interact with the server.

## Hints

### Network Keys

All network keys must specified as 16-byte hexadecimal strings (32 characters). A simple way to generate a random network key is with the following command:

```shell
$ < /dev/urandom tr -dc A-F0-9 | head -c32 ; echo
8387D66323E8209C58B0C317FD1F4251
```

All keys should be unique; sharing keys between multiple security classes is a security risk. See the Z-Wave JS [Key management](https://zwave-js.github.io/node-zwave-js/#/getting-started/security-s2?id=key-management) docs for further details.

At a minimum, the S0 (Legacy) network key is required, otherwise the zwave-js-server will fail to start. The S2 keys are optional but highly recommended. If unspecified, S2 inclusion will not be available.

### USB Path

Instead of using the `USB_PATH` environment variable, map the USB controller device path to the container's default of `/dev/zwave`.

### User Device Configuration Files

Use the `/cache/config` directory to easily test new device configuration files or modifications to existing ones. The files located in this directory will supplement or override the embedded device configuration database. When the container is restarted the driver logs will indicate which file was loaded:

```text
2021-06-19T06:19:18.506Z CNTRLR   [Node 007] Embedded device config loaded
2021-06-19T06:21:43.793Z CNTRLR   [Node 008] User-provided device config loaded
```

### Cache Lock Files

Z-Wave JS uses directories as lock files to prevent the cache files from being modified by multiple concurrent processes; this helps prevent against cache corruption. These directories are located in the cache directory, next to the actual cache files. The lock technique updates the `mtime` (Modified time) of the lock file every ~1 second. If your storage media is sensitive to frequent writes, such as an SD card, you may want to relocate the lock files to another directory, such as a tmpfs. To relocate the cache files, set the `ZWAVEJS_LOCK_DIRECTORY` environment variable to an alternate path, preferably some kind of tmpfs on the host. Here's an example snippet for a compose file:

```yaml
    environment:
      ZWAVEJS_LOCK_DIRECTORY: "/run/lock/zwave-js"
    volumes:
      - /run/lock/zwave-js:/run/lock/zwave-js
```

The environment variable tells Z-Wave JS to store the lock files in the directory `/run/lock/zwave-js`. The volume entry maps the hosts `/run/lock/zwave-js` directory, which is a tmpfs, to the container directory with the same name. The results being that the lock files created in the container are located in tmpfs on the host.

The path `/run/lock` is usually mounted as a tmpfs. Another candidate might be `/tmp/zwave-js`.
