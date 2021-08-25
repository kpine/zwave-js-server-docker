module.exports = {
  logConfig: {
    filename: process.env.LOGFILENAME,
    forceConsole: true,
  },

  storage: {
    cacheDir: "/cache",
    deviceConfigPriorityDir: "/cache/config",
  },

  securityKeys: {
    S2_AccessControl: process.env.S2_ACCESS_CONTROL_KEY,
    S2_Authenticated: process.env.S2_AUTHENTICATED_KEY,
    S2_Unauthenticated: process.env.S2_UNAUTHENTICATED_KEY,
    S0_Legacy: process.env.S0_LEGACY_KEY || process.env.NETWORK_KEY
  },
};
