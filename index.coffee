
cors = require 'cors'

Controllers = require "./lib/controllers"

corsOpts =
  methods: ["HEAD", "PATCH", "POST", "OPTIONS", "GET"]
  allowedHeaders: [
    "Origin", "X-Requested-With", "Content-Type", "Accept",
    "Upload-Length", "Upload-Offset", "Authorization"
  ]
  exposedHeaders: ["Location", "Upload-Offset"]


exports.initApp = (app, db) ->

  controllers = Controllers(db.models.upload)

  app.options('/', controllers.serverInfo)

  app.use cors(corsOpts)

  app.post("/", controllers.checkVersion, controllers.createFile)
  app.head("/:id(*)", controllers.checkVersion, controllers.headFile)
  app.get("/:id(*)", controllers.getFile)
  app.patch("/:id(*)", controllers.checkVersion, controllers.patchFile)


exports.getInfo = (file, req, cb) ->
  u = upload.Upload({files: filesDir}, file)
  status = u.load()
  return cb status.error if status.error?

  status.info.filepath = path.join filesDir, file
  status.url = upload.getFileUrl(file, req)
  cb null, status.info
