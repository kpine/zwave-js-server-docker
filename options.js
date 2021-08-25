// Setup keys based on the expected environment variables.
// The server and driver don't allow blank or undefined keys,
// so we need to pre-process the environment variables and
// skip any undefined or blank ones. The server checks the key
// lengths and converts to a Buffer for us.
keys = {
  S2_AccessControl: process.env.S2_ACCESS_CONTROL_KEY,
  S2_Authenticated: process.env.S2_AUTHENTICATED_KEY,
  S2_Unauthenticated: process.env.S2_UNAUTHENTICATED_KEY,
  S0_Legacy: process.env.S0_LEGACY_KEY || process.env.NETWORK_KEY,
};

config = {
  logConfig: {
    filename: process.env.LOGFILENAME,
    forceConsole: true,
  },

  storage: {
    cacheDir: "/cache",
    deviceConfigPriorityDir: "/cache/config",
  },

  securityKeys: {},
};

// Copy non-blank / undefined keys
for (const [name, key] of Object.entries(keys)) {
  if (key) {
    config.securityKeys[name] = key;
  }
}

module.exports = config;
