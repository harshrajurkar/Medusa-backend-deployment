module.exports = {
  projectConfig: {
    // other configurations
    database_extra: process.env.NODE_ENV !== "development" ?
      {
        ssl: {
          rejectUnauthorized: false,
        },
      } : {},
  },
  // other configurations
}
