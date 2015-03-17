
fs = require 'fs'
path = require 'path'
cors = require 'cors'

controllers = require "./lib/controllers"

if process.env.BTUSPLUGIN
  plugin = require process.env.BTUSPLUGIN
else
  plugin = require "./lib/defaultplugin"


corsOpts =
  methods: ["HEAD", "PATCH", "POST", "OPTIONS", "GET"]
  allowedHeaders: [
    "Origin", "X-Requested-With", "Content-Type", "Accept",
    "Final-Length", "Offset", "Authorization"
  ]
  exposedHeaders: ["Location", "Offset"]


exports.initApp = (app) ->

  filesDir = process.env.FILESDIR || path.join(__dirname, 'files')
  if not fs.existsSync(filesDir)
    fs.mkdirSync(filesDir)
  serverString = process.env.SERVERSTRING || 'BrewTUS/0.1'

  app.use (req, res, next) ->
    res.setHeader("Server", serverString)
    res.locals.FILESDIR = filesDir
    res.locals.plugin = plugin
    next()

  app.use cors(corsOpts)

  app.post("/", controllers.createFile)
  app.head("/:id(*)", controllers.headFile)
  app.get("/:id(*)", controllers.getFile)
  app.patch("/:id(*)", controllers.patchFile)


exports.serveTest = (app) ->
  app.get("up.html", controllers.testUploadPage)
