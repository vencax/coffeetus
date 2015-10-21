
cors = require 'cors'

Controllers = require "./lib/controllers"

corsOpts =
  methods: ["HEAD", "PATCH", "POST", "OPTIONS", "GET"]
  allowedHeaders: [
    "Origin", "X-Requested-With", "Content-Type", "Accept",
    "Upload-Length", "Upload-Offset", "Authorization"
  ]
  exposedHeaders: ["Location", "Upload-Offset"]


module.exports = (db) ->

  controllers = Controllers(db.models.upload)

  _initApp = (app) ->
    app.options('/', controllers.serverInfo)

    app.use cors(corsOpts)

    app.post("/", controllers.checkVersion, controllers.createFile)
    app.head("/:id(*)", controllers.checkVersion, controllers.headFile)
    app.get("/:id(*)", controllers.getFile)
    app.patch("/:id(*)", controllers.checkVersion, controllers.patchFile)
    app.delete("/:id(*)", controllers.checkVersion, controllers.terminate)


  initApp: _initApp
  getInfo: controllers.getInfo
