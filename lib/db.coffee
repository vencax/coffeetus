
Sequelize = require 'sequelize'

opts = {}

if process.env.DATABASE_URL
  opts = {}
  if process.env.NODE_ENV? and process.env.NODE_ENV is "devel"
    opts.logging = false

  if process.env.DATABASE_URL.indexOf("sqlite://") >= 0
    opts.storage = "db.sqlite"

  sequelize = new Sequelize(process.env.DATABASE_URL, opts)
else
  # in MEMORY sqlite
  console.log('## using in memory sqlite')
  sequelize = new Sequelize('database', 'username', 'password',
    dialect: 'sqlite'
  )

module.exports = (cb) ->

  require('./models')(sequelize, Sequelize)

  sequelize.sync().then (migrations) ->
    cb(null, sequelize)
  .catch (err) ->
    cb('Unable to sync database: ' + err)
