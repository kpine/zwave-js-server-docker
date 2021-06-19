module.exports = {
  logConfig: {
    filename: process.env.LOGFILENAME,
  },

  storage: {
    cacheDir: "/cache",
    deviceConfigPriorityDir: "/cache/config",
  },

  networkKey: process.env.NETWORK_KEY,
};
