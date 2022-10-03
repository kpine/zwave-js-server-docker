#!/usr/bin/env bash
# shellcheck disable=SC2312

set -euo pipefail

DEFAULT_DEV_PATH=/dev/ttyUSB0
DEFAULT_FW_DIR=/tmp

dev_path=${ZFWU_DEVICE_PATH:-${DEFAULT_DEV_PATH}}
fw_dir=${ZFWU_FW_DIR:-${DEFAULT_FW_DIR}}

function usage {
  cat << EOF >&2
USAGE:
    $(basename "$0") [-d DEVICE_PATH] [-f FW_DIR]

For more information use -h
EOF
  exit 1
}

function help {
  cat << EOF >&2
$(basename "$0")
Update Z-Wave controller firmware (700-series or later)

USAGE:
    $(basename "$0") [-d DEVICE-PATH] [-f FW-DIR]

OPTIONS:
   -d <device-path>     The controller's serial device path. Also set with
                        environment variable ZFWU_DEVICE_PATH.
                        [default: ${DEFAULT_DEV_PATH}]
   -f <fw-dir>          Optional default upload directory for minicom. Also set
                        with environment variable ZFWU_FW_DIR.
                        [default: ${DEFAULT_FW_DIR}]
EOF
  exit 1
}

function error {
  for message; do
    echo "${message}" >&2
  done

  exit 1
}

function error_usage {
  for message; do
    echo "${message}" >&2
  done
  echo >&2

  usage
}

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
      error_usage "missing value for option -${OPTARG}"
      ;;
    ?)
      error_usage "invalid option: -${OPTARG}"
      ;;
  esac
done

# If this is the HAOS SSH & Web Terminal add-on, install the software
if [[ ${HOSTNAME} == "a0d7b954-ssh" ]] && command -v apk &> /dev/null; then
  ! command -v minicom &>/dev/null && apk add minicom --no-cache --quiet --no-progress
  ! command -v lsx &>/dev/null && apk add lrzsz --no-cache --quiet --no-progress --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
fi

# On Debian/Ubuntu, lrzsz xmodem is installed as `sx`.
# On Alpine/MacOS, lrzsz xmodem is installed as `lsx`.
# Find the correct one.
SX_BIN=
for x in sx lsx; do
  ! sx_bin=$(command -v "${x}") && continue
  ! grep -q 'sx.*lrzsz' <(${sx_bin} --version 2> /dev/null) && continue
  SX_BIN="${sx_bin}"
  break
done

[[ ! -x $(command -v minicom) ]] && error "minicom must be installed"
[[ ! -x ${SX_BIN} ]] && error "lrzsz must be installed"
[[ ! -e "${dev_path}" ]] && error_usage "Device path ${dev_path} does not exist"
[[ ! -c "${dev_path}" ]] && error_usage "Device path ${dev_path} is not a valid serial device"
[[ ! -w "${dev_path}" || ! -r "${dev_path}" ]] && error_usage "No permission to read from or write to the serial device."
[[ ! -d "${fw_dir}" ]] && error_usage "Firmware directory ${fw_dir} is not valid"

cat << EOF > ~/.minirc.zwave
# Machine-generated file - use "minicom -s" to change parameters.
pu pname1           YUNYY
pu pname2           YUNYY
pu pname3           YUNYNxmodem
pu pname4           NDNYY
pu pname5           NDNYY
pu pname6           YDNYN
pu pname7           YUYNN
pu pname8           NDYNN
pu pname9           YUNYN
pu pprog3           ${SX_BIN} -vv
pu updir            ${fw_dir}
pu baudrate         115200
pu bits             8
pu parity           N
pu stopbits         1
pu rtscts           No
EOF

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
