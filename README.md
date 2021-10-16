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
- `LOGFILENAME`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver log filename (only used when `LOGTOFILE` is `true`). The default is `/logs/zwave_%DATE%.log`. Note that the driver will automatically rotate the logfiles using a date based scheme.
- `LOGLEVEL`: Set this to [configure](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=logconfig) the driver loglevel.
- `S2_ACCESS_CONTROL_KEY`: The network key for the S2 Access Control security class.
- `S2_AUTHENTICATED_KEY`: The network key for the S2 Authenticated security class.
- `S2_UNAUTHENTICATED_KEY`: The network key for the S2 Unauthenticated security class.
- `S0_LEGACY_KEY`: The network key for the S0 (Legacy) security class. This replaces the deprecated `NETWORK_KEY` variable.
- `USB_PATH`: The device path of the Z-Wave USB controller. Defaults to `/dev/zwave`. Use of this variable is unnecessary if the controller device path is mapped from the host as `/dev/zwave`.
- `ZWAVEJS_ENABLE_SOFT_RESET`: Set this to any value to enable the [soft-reset](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=softreset) functionality. This requires special container configurations so it is disabled by default. See instructions below for configuring the container to support this.

### Directories

- `/cache` - The driver [cache directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). A volume or bind mount should be mapped to this directory to persist the network information between container restarts.
- `/cache/config` - The driver [device configuration priority directory](https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions). Used to load your custom device configuration files. The directory is automatically created if `/cache` is a named volume, otherwise it must be created manually or mapped as a volume/bind mount.
- `/logs` - When logging to file is enabled, this is the directory where the driver log file is written to. Assign a volume or bind mount to this directory to access and save the logfiles outside of the container.

### Ports

- `3000` - The zwave-js-server websocket port. External applications, such as Home Assistant, must be able to connect to this port to interact with the server.

## Hints

### Network Keys

All network keys must specified as 16-byte hexidecimal strings (32 characters). A simple way to generate a random network key is with the following command:

```shell
$ < /dev/urandom tr -dc A-F0-9 | head -c32 ; echo
8387D66323E8209C58B0C317FD1F4251
```

All keys should be unique; sharing keys between multiple security classes is a security risk. See the Z-Wave JS [Key management](https://zwave-js.github.io/node-zwave-js/#/getting-started/security-s2?id=key-management) docs for futher details.

At a minimum, the S0 (Legacy) network key is required, otherwise the zwave-js-server will fail to start. The S2 keys are optional but highly recommended. If unspecified, S2 inclusion will not be available.

### USB Path

Instead of using the `USB_PATH` environment variable, map the USB controller device path to the container's default of `/dev/zwave`.

### User Device Configuration Files

Use the `/cache/config` directory to easily test new device config files or modifications to existing ones. The files located in this directory will supplement or override the embedded device config database. When the container is restarted the driver logs will indicate which file was loaded:

```text
2021-06-19T06:19:18.506Z CNTRLR   [Node 007] Embedded device config loaded
2021-06-19T06:21:43.793Z CNTRLR   [Node 008] User-provided device config loaded
```

### Dynamically Created Devices

When secured, Docker containers typically do not handle dynamically created USB. If you are using this container and remove and re-insert the USB stick, not only will Z-Wave JS exit due to the lost serial port, the container will be unable to detect the new device when it is re-inserted.

Additionally Z-Wave JS v8.6.0 has the ability to perform a serial soft-reset, which manifests in the OS as a device removal and addition. Since Docker does not support this behavior without special configuration, the soft-reset is disabled by default when running in a container. The soft-reset is required for functionality such as changing the RF region or restoring an NVM backup. There are several ways to support this functionality described here.

#### Privileged Containers

Running a privileged container is the easiest way to support dynamically created devices, however privileged mode is always a last resort. Privileged mode gives containers nearly all the capabilities a host has. Often this mode is required to access hardware devices, and this case is no different. When you run in privileged mode, all of the device files in `/dev` are available to use by the container. If the USB controller is reset, the device will be available when it is ready.

This example creates a temporary container with privileged mode. It's no longer necessary to pass in a device name with `--device` since privileged mode allows access to all devicese. On the other-hand, you cannot use the persistent by-id symlinks and must use the raw device name. This works fine if the USB device is never renamed, e.g. from `/dev/ttyUSB0` to `/dev/ttyUSB1`. If your device name does change, this is not a solution.

```shell
$ docker run --rm -it \
    -p 3000:3000 \
    -v $PWD/cache:/cache \
    --env-file=.env \
    --env USB_PATH=/dev/ttyACM0 \
    --privileged \
    kpine/zwave-js-server:latest
```

This example is similar, but allows use of the by-id symlinks. In this case the entire `/dev` directory is mapped from the host into the container. Privileged mode is still required. Despite being a read-only volume, the serial port is still writable and you are unable to delete or modify the files. When the USB controller is reset, the host will re-create the persistent symlinks which will be visible in the container.

```shell
$ docker run --rm -it \
    -p 3000:3000 \
    -v $PWD/cache:/cache \
    --env-file=.env \
    --env USB_PATH=/dev/serial/by-id/usb-0658_0200_E2061B02-4A02-0114-3A06-FD1871291660-if00 \
    --privileged \
    -v /dev:/dev:ro \
    kpine/zwave-js-server:latest
```

The last option for privileged containers would be to run udev inside of the container. This container udev instance would create the by-id symlinks instead, and the `/dev` volume mount would no longer be required. The Balena Docker images support this functionality, so [take a look](https://www.balena.io/docs/reference/base-images/base-images/#working-with-dynamically-plugged-devices) if that is interesting. This project will not implement the udev functionality, but you can always build your own using a Balena base image.

#### Device Cgroup Rules

A more secure configuration is to use [device cgroup rules](https://docs.docker.com/engine/reference/commandline/create/#dealing-with-dynamically-created-devices---device-cgroup-rule). A device cgroup rule allows a container to have access to specific devices, without having to enable privileged mode. The trick is that when a device is added during the container runtime, the host must create a new character device file inside the container. This is typically done with a udev script.

In order to write the cgroup rule, the device's major number is required. This can be obtained with the following command:

```shell
$ echo $((0x$(stat -c "%t" /dev/ttyACM0)))
166
```

The major number will depend in your type of USB controller. Possible values might be 166, 167, 188, or 189. When a USB device is reset, the major number will stay the same, but the minor number might change. For that reason we setup a rule that allows access to any device file that matches the major number.

```shell
$ docker run --rm -it \
    -p 3000:3000 \
    --name=zjs \
    -v $PWD/cache:/cache \
    --env-file=.env \
    --device /dev/serial/by-id/usb-0658_0200_E2061B02-4A02-0114-3A06-FD1871291660-if00:/dev/zwave \
    --device-cgroup-rule='c 166:* rmw' \
    kpine/zwave-js-server:latest
```

In the example, we return to mapping the host USB path to `/dev/zwave`, and also configure the cgroup rule to all read-modify-write access to the controller. The device mapping is still required at container creation time. To complete this, we need a udev script that runs anytime the stick is plugged in, and re-creates the `/dev/zwave` device inside the container. This script is the bare minumum; you may want to customize it or make it more robust.

```text
$ cat << EOF | sudo tee /etc/udev/rules.d
ACTION=="add", SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", RUN+="docker exec zjs mknod zwave c $major $minor"
EOF

$ sudo udevadm control --reload
```

The udev rule is triggered when a device that identifies as a 500-series USB Z-Wave controller is inserted. It runs `docker exec` to run a command in a the container named `zjs`. The `mknod` command creates a new `/dev/zwave` device file with the new major and minor numbers. You can match on other properties like serial number (if provided) to make the rule more specific.

Here's a rule for a USB7 controller, which also considers the serial number.

```text
ACTION=="add", SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ENV{ID_SERIAL_SHORT}=="60c64ab0012dca943f04442969a5bfc8", RUN+="docker exec zjs mknod zwave c $major $minor"
```

Generally, serial number is not required unless you have multiples of the same product. The identifiers for the 700-series are very generic and match several other serial-USB products. Some devices like the Aeotec Z-Stick Gen5 do not even have serial numbers.

The command `udevadm info -q property /dev/ttyACM0` will display all the environment variables that can be used in a udev rule, e.g. `ENV{ID_SERIAL_SHORT}`. The command `udevadm info -a /dev/ttyACM0` will display all the attributes of the device and its parents that can be matched, e.g. `ATTRS{idVendor}`.
