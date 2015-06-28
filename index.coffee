
cors = require 'cors'
bodyParser = require 'body-parser'

Controllers = require "./lib/controllers"

corsOpts =
  methods: ["HEAD", "PATCH", "POST", "OPTIONS", "GET"]
  allowedHeaders: [
    "Origin", "X-Requested-With", "Content-Type", "Accept",
    "Final-Length", "Offset", "Authorization"
  ]
  exposedHeaders: ["Location", "Offset"]


exports.initApp = (app, db) ->

  serverString = process.env.SERVERSTRING || 'BrewTUS/0.1'

  controllers = Controllers(db.models.upload)

  app.use cors(corsOpts)

  app.post("/", bodyParser.json(), controllers.createFile)
  app.head("/:id(*)", controllers.headFile)
  app.get("/:id(*)", controllers.getFile)
  app.patch("/:id(*)", controllers.patchFile)


exports.getInfo = (file, req, cb) ->
  u = upload.Upload({files: filesDir}, file)
  status = u.load()
  return cb status.error if status.error?

  status.info.filepath = path.join filesDir, file
  status.url = upload.getFileUrl(file, req)
  cb null, status.info
