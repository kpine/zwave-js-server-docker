module.exports = {
  logConfig: {
    filename: process.env.LOGFILENAME,
  },

  storage: {
    cacheDir: "/cache",
  },

  networkKey: process.env.NETWORK_KEY,
};
