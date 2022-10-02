#!/usr/bin/env bash

set -eu

DEFAULT_DEV_PATH=/dev/ttyUSB0

dev_path=${DEVICE_PATH:-${DEFAULT_DEV_PATH}}
fw_dir=${FW_DIR:-}

function usage {
  cat << EOF 2>&1
USAGE:
    $(basename "$0") [-d DEVICE_PATH] [-f FW_DIR]

For more information use -h
EOF
  exit 1
}

function help {
  cat << EOF 2>&1
$(basename "$0")
Update Z-Wave controller firmware (700-series or later)

USAGE:
    $(basename "$0") [-d DEVICE-PATH] [-f FW-DIR]

OPTIONS:
   -d <device-path>     The Controller's serial device path. Also set with
                        environment variable DEVICE_PATH.
                        [default: ${DEFAULT_DEV_PATH}]
   -f <fw-dir>          Optional default upload directory for minicom. Also set
                        with environment variable FW_DIR. If not set the
                        current directory will be used.
EOF
  exit 1
}

function error {
  echo "$@" >&2
  exit 1
}

if ! command -v minicom &> /dev/null; then
  error "minicom was not found, please install it"
fi

while getopts :d:f:h arg; do
  case ${arg} in
    h)
      help
      exit 0
      ;;
    d)
      dev_path="${OPTARG}"
      ;;
    f)
      fw_dir="${OPTARG}"
      ;;
    :)
      printf "missing value for option -%s\n\n" "${OPTARG}"
      usage
      ;;
    ?)
      printf "invalid option: -%s\n\n" "${OPTARG}"
      usage
      ;;
  esac
done

if [[ -z "${dev_path}" ]]; then
  usage
fi

if [[ ! -c "${dev_path}" ]]; then
  printf "Device path %s is not a valid serial device\n\n" "${dev_path}"
  usage
fi

if [[ ! -w "${dev_path}" || ! -r "${dev_path}" ]]; then
    printf "No permission to read from or write to the serial device.\n"
    exit 1
fi

if [[ -n "${fw_dir}" && ! -d "${fw_dir}" ]]; then
  printf "Firmware directory %s is not valid\n\n" "${fw_dir}"
  usage
fi

cat << EOF > ~/.minirc.zwave
# Machine-generated file - use "minicom -s" to change parameters.
pu pname1           YUNYY
pu pname2           YUNYY
pu pname4           NDNYY
pu pname5           NDNYY
pu pname6           YDNYN
pu pname7           YUYNN
pu pname8           NDYNN
pu pname9           YUNYN
pu baudrate         115200
pu bits             8
pu parity           N
pu stopbits         1
pu rtscts           No
EOF

if [[ -n "${fw_dir}" ]]; then
  cat << EOF >> ~/.minirc.zwave
pu updir            ${fw_dir}
EOF
fi

zwave_runscript=$(cat <<EOF
print Activating the controller's bootloader. It will appear in about 10 seconds...
send "\1\3\0\10\364"
sleep 1
print "9..."
sleep 1
print "8..."
sleep 1
print "7..."
sleep 1
print "6..."
sleep 1
print "5..."
sleep 1
print "4..."
sleep 1
print "3..."
sleep 1
print "2..."
sleep 1
print "1..."
sleep 1
send "\1\3\0\47\333"
EOF
)

minicom -D "${dev_path}" -S <(echo -E "${zwave_runscript}") zwave
