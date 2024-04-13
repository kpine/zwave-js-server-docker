# zwave-js-server-docker

A minimal docker container for [Z-Wave JS Server](https://github.com/zwave-js/zwave-js-server/). This container provides a usable Z-Wave JS Server and little else.

For a more functional application that also provides the Server, use [Z-Wave JS UI](https://github.com/zwave-js/zwave-js-ui) instead.

## Docker Configuration

The Z-Wave JS driver stores information about the Z-Wave network in a set of cache files. When the server restarts, the driver loads the network information from the cache. Without this information the network will not be fully usable right away. Therefore it is very important that the cache files are persisted between container restarts.

The `docker run` examples below use an environment file to provide all of the Z-Wave network keys.

```shell
$ cat .env
S2_ACCESS_CONTROL_KEY=7764841BC794A54442E324682A550CEF
S2_AUTHENTICATED_KEY=66EA86F088FFD6D7497E0B32BC0C8B99
S2_UNAUTHENTICATED_KEY=2FAB1A27E19AE9C7CC6D18ACEB90C357
S0_LEGACY_KEY=17DFB0C1BED4CABFF54E4B5375E257B3
LR_S2_ACCESS_CONTROL_KEY=61BEF779F9DF0827CD9870B719D074BB
LR_S2_AUTHENTICATED_KEY=905B869063266296AE5159EEDBEE038D
```

### Run with a volume mount

```shell
# Create a persistent volume for the driver cache
$ docker volume create zjs-storage

# starts the server and uses the volume as the persistent cache directory
$ docker run -d -p 3000:3000 --name=zjs -v zjs-storage:/cache --env-file=.env --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" ghcr.io/kpine/zwave-js-server:latest
```

### Run with a bind mount

```shell
# starts the server and uses a local folder as the persisent cache directory
$ docker run -d -p 3000:3000 --name=zjs -v "$PWD/cache:/cache" --env-file=.env --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" ghcr.io/kpine/zwave-js-server:latest
```

### Docker Compose

Docker Compose is a simple way to maintain a container configuration.

Example of a minimal `docker-compose.yaml` file:

```yaml
services:
  zjs:
    container_name: zjs
    image: ghcr.io/kpine/zwave-js-server:latest
    restart: unless-stopped
    environment:
      - "S2_ACCESS_CONTROL_KEY=7764841BC794A54442E324682A550CEF"
      - "S2_AUTHENTICATED_KEY=66EA86F088FFD6D7497E0B32BC0C8B99"
      - "S2_UNAUTHENTICATED_KEY=2FAB1A27E19AE9C7CC6D18ACEB90C357"
      - "S0_LEGACY_KEY=17DFB0C1BED4CABFF54E4B5375E257B3"
      - "LR_S2_ACCESS_CONTROL_KEY=61BEF779F9DF0827CD9870B719D074BB"
      - "LR_S2_AUTHENTICATED_KEY=905B869063266296AE5159EEDBEE038D"
    devices:
      - "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave"
    volumes:
      - ./cache:/cache
    ports:
      - "3000:3000"
```

### Environment variables

- `LOGTOFILE`: Set this to `true` to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver to log to a file.
- `LOGFILENAME`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log filename (only used when `LOGTOFILE` is `true`). The default is `/logs/zwavejs`, which results in files named `zwavejs_%DATE%.log`. Note that the driver will automatically rotate the log files using the date based scheme.
- `LOGMAXFILES`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the maximum number of log files to keep. Z-Wave JS rotates log files once a day, so this corresponds to the number of days of log files to keep.
- `LOGLEVEL`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log level.
- `S2_ACCESS_CONTROL_KEY`: The network key for the S2 Access Control security class.
- `S2_AUTHENTICATED_KEY`: The network key for the S2 Authenticated security class.
- `S2_UNAUTHENTICATED_KEY`: The network key for the S2 Unauthenticated security class.
- `S0_LEGACY_KEY`: The network key for the S0 (Legacy) security class.
- `LR_S2_ACCESS_CONTROL_KEY`: The network key for the Long Range S2 Access Control security class.
- `LR_S2_AUTHENTICATED_KEY`: The network key for the Long Range S2 Authenticated security class.
- `USB_PATH`: The device path of the Z-Wave USB controller. Defaults to `/dev/zwave`. Use of this variable is unnecessary if the controller device path is mapped from the host as `/dev/zwave`.
- `FIRMWARE_UPDATE_API_KEY`: The API key used to access the Z-Wave JS Firmware Update Service. By default, no key is configured. Usually it is not necessary to configure this, unless you are a commercial user. See the [Firmware Update API Key](#firmware-update-api-key) section for details.
- `ENABLE_DNS_SD`: Set this to `true` to enable DNS Service Discovery. The default is disabled. Enabling this only works if you are using host networking.

### Directories

- `/cache` - The driver [cache directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). A volume or bind mount should be mapped to this directory to persist the network information between container restarts.
- `/cache/config` - The driver [device configuration priority directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). Used to load your custom device configuration files. The directory is automatically created if `/cache` is a named volume, otherwise it must be created manually or mapped as a volume/bind mount.
- `/logs` - When logging to file is enabled, this is the directory where the driver log file is written to. Assign a volume or bind mount to this directory to access and save the log files outside of the container.

### Ports

- `3000` - The zwave-js-server websocket port. External applications, such as Home Assistant, must be able to connect to this port to interact with the server.

## Details

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

### Controller Firmware Updates (OTW)

The [`@zwave-js/flash`](https://www.npmjs.com/package/@zwave-js/flash) command line utility is included in the Docker image to support Over-The-Wire (OTW) firmware updates of controllers. Download the appropriate firmware file for your controller and issue the flash command. Be sure to stop any running Z-Wave JS server before doing so.

```shell
docker run --rm -it -v "$PWD/fw:/fw" --device "/dev/ttyUSB0:/dev/zwave" ghcr.io/kpine/zwave-js-server:latest flash /fw/fw.gbl
```

The command expects the device path to be `/dev/zwave` by default, or whatever environment variable `USB_PATH` is set to.

See the [wiki page](https://github.com/kpine/zwave-js-server-docker/wiki/700-series-Controller-Firmware-Updates-(Linux)) for more information.

### User Device Configuration Files

Use the `/cache/config` directory to easily test new device configuration files or modifications to existing ones. The files located in this directory will supplement or override the embedded device configuration database. When the container is restarted the driver logs will indicate which file was loaded:

```text
2021-06-19T06:19:18.506Z CNTRLR   [Node 007] Embedded device config loaded
2021-06-19T06:21:43.793Z CNTRLR   [Node 008] User-provided device config loaded
```

### Serial Soft-Reset

Z-Wave JS performs a soft-reset (restart) of the Z-Wave controller during startup, and during certain operations such as NVM backups and restores. The soft-reset can result in a USB disconnect for some Z-Wave controllers, which may cause problems with certain container runtimes or host configurations. If you observe that Z-Wave JS has trouble finding the USB device, you may try opting out of this functionality by setting the `ZWAVEJS_DISABLE_SOFT_RESET` environment variable, or setting the `softReset` driver feature option to `false`. For more details, see the [`softReset`](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=softreset) and [`ZWaveOptions`](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions) documentation.

If you continue to have issues even after disabling soft-reset, you may also need to disable the unresponsive controller recovery feature. You can opt out of this functionality by setting the `ZWAVEJS_DISABLE_UNRESPONSIVE_CONTROLLER_RECOVERY` environment variable, or setting the `unresponsiveControllerRecovery` driver feature option to `false`. For more details, see the [`ZWaveOptions`](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions) documentation.

### Cache Lock Files

Z-Wave JS uses directories as lock files to prevent the cache files from being modified by multiple concurrent processes; this helps prevent against cache corruption. These directories are located in the cache directory, next to the actual cache files. The locking technique updates the `mtime` (Modified time) of the lock file every ~1 second. If your storage media is sensitive to frequent writes, such as an SD card, you may want to relocate the lock files to another directory, such as a tmpfs. To relocate the cache files, set the `ZWAVEJS_LOCK_DIRECTORY` environment variable to an alternate path, preferably some kind of tmpfs on the host. Here is an extract of a compose file:

```yaml
services:
  zjs:
    environment:
      ZWAVEJS_LOCK_DIRECTORY: "/run/lock/zwave-js"
    volumes:
      - /run/lock/zwave-js:/run/lock/zwave-js
```

The environment variable tells Z-Wave JS to store the lock files in the directory `/run/lock/zwave-js`. The volume entry maps the hosts `/run/lock/zwave-js` directory, which is a tmpfs, to the container directory with the same name. The end result is that the lock files created in the container are located in the tmpfs of the host. The path `/run/lock` is usually mounted as a tmpfs. Another candidate might be `/tmp/zwave-js`.

Note that locating the locks in a central place on the host ensures that multiple containers with the same configuration will be aware of the locks. However, if Z-Wave JS is run in another instance without the same lock directory configuration, it will not see the locks and this will bypass the lock protections, allowing for the chance that the cache will be corrupted. When the locks are located in the default location, all instances of Z-Wave JS using the default configuration will see the locks. So use this feature with care.

### Firmware Update API Key

Z-Wave JS has an [online web service](https://github.com/zwave-js/firmware-updates/) that provides information about firmware updates for your devices. Use of this service requires an API key. The Z-Wave JS organization has provided this project with its own key. This key is only valid when used for non-commercial purposes, and is not permitted for commercial usage.
If you are a commercial organization using this application, you must [request](https://github.com/zwave-js/firmware-updates#api-keys) and configure your own key.

If you are using the Z-Wave integration with Home Assistant, you do not need to enable or install an API key. The integration provides the key when accessing the firmware update APIs. This is true for any client application that makes use of the firmware update APIs with its own keys.

If you use a client that does not support its own API key, and you are a non-commercial user, you can enable the built-in key by setting the `FIRMWARE_UPDATE_API_KEY` to `-`. By doing so you agree that you are not a commercial user.

If you have your own key, i.e. you are a commercial user, you can set `FIRMWARE_UPDATE_API_KEY` to that key.

If the `FIRMWARE_UPDATE_API_KEY` environment variable is empty (the default), no API key will be configured. In that case a client application would be responsible for setting it, otherwise the firmware update service may not be functional or incur more restrictive rate-limiting.
