function getLogConfig() {
  let config = {
    forceConsole: true,
  };

  if (process.env.LOGFILENAME) {
    config.filename = process.env.LOGFILENAME;
  }

  return config;
}

// Obtain the security keys from the environment variables.
// The server and driver don't allow blank or undefined keys,
// so skip any unset/blank environment variables. The server checks
// the key lengths and converts to a Buffer for us.
function getSecurityKeys() {
  const env_keys = {
    S2_AccessControl: process.env.S2_ACCESS_CONTROL_KEY,
    S2_Authenticated: process.env.S2_AUTHENTICATED_KEY,
    S2_Unauthenticated: process.env.S2_UNAUTHENTICATED_KEY,
    S0_Legacy: process.env.S0_LEGACY_KEY,
  };

  let keys = {};
  for (const [name, key] of Object.entries(env_keys)) {
    if (key) {
      keys[name] = key;
    }
  }

  return keys;
}

function getApiKeys() {
  let fw_key = process.env.FIRMWARE_UPDATE_API_KEY;

  if (!fw_key) {
    return undefined;
  }

  if (fw_key === "-") {
    // This API key is valid only for non-commercial users. If you are a commercial user
    // you **must** request your own key: https://github.com/zwave-js/firmware-updates#api-keys
    fw_key = "1e1cf4e7735a3cbf59e9349ba9d936caec74466578fd0fc8b516059474cdc5a41c0dd69b";
  }

  return { firmwareUpdateService: fw_key };
}

module.exports = {
  logConfig: getLogConfig(),
  storage: {
    cacheDir: "/cache",
    deviceConfigPriorityDir: "/cache/config",
  },
  securityKeys: getSecurityKeys(),
  apiKeys: getApiKeys(),
  userAgent: { "kpine/zwave-js-server": process.env.BUILD_VERSION || "unknown" },
};
