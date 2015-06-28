
fs = require "fs"
path = require "path"
uuid = require "node-uuid"
sanitize = require "sanitize-filename"
mkdirp = require "mkdirp"
touch = require "touch"

FileInfo = require "./fileinfo"

filesDir = process.env.FILESDIR || path.join(__dirname, 'files')

if not fs.existsSync(filesDir)
  fs.mkdirSync(filesDir)

# creates name of the created file
_getFileId = (req) ->
  if req.query.filename or req.body.filename
    fname = req.query.filename or req.body.filename
    parts = fname.split('/')
    for p in parts
      p = sanitize(p)
    return parts.join('/')
  else
    return uuid.v1()

_getFileUrl = (fileId, req) ->
  reqpath = req.originalUrl.split('?')[0]
  if reqpath[reqpath.length-1] == '/'
    return "#{req.protocol}://#{req.headers.host}#{reqpath}#{fileId}"
  else
    return "#{req.protocol}://#{req.headers.host}#{reqpath}/#{fileId}"


module.exports = (UploadModel) ->

  _fileInfo = FileInfo(UploadModel)

  #GET MUST return Content-Length == Final-Length
  getFile: (req, res, next) ->
    return res.status(404).send("Not Found") unless req.params.id?

    _fileInfo.load req.params.id, (err, fleInfo)->
      return res.status(400).send(err) if err

      if fleInfo.offset != fleInfo.final_length
        return res.status(404).send("Not Found")

      res.setHeader "Content-Length", fleInfo.final_length
      stream = fs.createReadStream(path.join(filesDir, req.params.id))
      stream.pipe(res)


  #Implements 6.1. File Creation
  createFile: (req, res, next) ->

    #6.1.3.1. POST
    #The request MUST include a Final-Length header
    unless req.headers["final-length"]?
      return res.status(400).send("Final-Length Required")

    finalLength = parseInt req.headers["final-length"]

    #The value MUST be a non-negative integer.
    if isNaN finalLength || finalLength < 0
      return res.status(400).send("Final-Length Must be Non-Negative")

    #generate fileId
    fileId = _getFileId(req)

    if fileId.indexOf('..') >= 0
      return res.status(400).send("Bad fileName")

    _fileInfo.create fileId, finalLength, (err, fileInfo)->
      return res.status(400).send(err) if err

      fileAbs = path.join(filesDir, fileId)
      folder = path.dirname(fileAbs)
      mkdirp.sync folder unless fs.existsSync folder
      touch fileAbs, {}, (err) ->
        return res.status(400).send(err) if err

        location = _getFileUrl(fileId, req)
        res.setHeader "Location", location
        res.status(201).send("Created")


  #Implements 5.3.1. HEAD
  headFile: (req, res, next) ->
    return res.status(404).send("Not Found") unless req.params.id

    _fileInfo.load req.params.id, (err, fleInfo)->
      return res.status(400).send(err) if err

      res.setHeader "Offset", fleInfo.offset
      res.setHeader "Connection", "close"
      res.send("Ok")


  #Implements 5.3.2. PATCH
  patchFile: (req, res, next) ->
    return res.status(404).send("file id not provided") unless req.params.id

    filePath = path.join filesDir, req.params.id
    return res.status(404).send("Not Found") unless fs.existsSync filePath

    #All PATCH requests MUST use Content-Type: application/offset+octet-stream.
    unless req.headers["content-type"]?
      return res.status(400).send("Content-Type Required")

    unless req.headers["content-type"] is "application/offset+octet-stream"
      return res.status(400).send("Content-Type Invalid")

    #5.2.1. Offset
    return res.status(400).send("Offset Required") unless req.headers["offset"]?

    #The value MUST be an integer that is 0 or larger
    offsetIn = parseInt req.headers["offset"]
    if isNaN offsetIn or offsetIn < 0
      return res.status(400).send("Offset Invalid")

    unless req.headers["content-length"]?
      return res.status(400).send("Content-Length Required")

    contentLength = parseInt req.headers["content-length"]
    if isNaN contentLength or contentLength < 1
      return res.status(400).send("Invalid Content-Length")

    _fileInfo.load req.params.id, (err, info)->
      return res.status(400).send(err) if err

      return res.status(400).send("Invalid Offset") if offsetIn > info.offset

      #Open file for writing
      filePath = path.join(filesDir, req.params.id)
      ws = fs.createWriteStream filePath, {flags: "r+", start: offsetIn}

      unless ws?
        return res.status(500).send("unable to create file fo #{req.params.id}")

      info.offset = offsetIn
      info.state = 1
      info.patchedOn = Date.now()
      info.bytesReceived = 0

      req.pipe ws

      req.on "data", (buffer) ->
        info.bytesReceived += buffer.length
        info.offset +=  buffer.length
        if info.offset > info.finalLength
          return res.status(500).send("Exceeded Final-Length")
        if info.received > contentLength
          return res.status(500).send("Exceeded Content-Length")

      req.on "end", ->
        # chunkError = res.locals.plugin.validateChunk(req, info)
        # if chunkError
        #   return res.status(400).send("Invalid Chunk: #{chunkError}")
        _fileInfo.save info, (err, saved)->
          return res.status(400).send(err) if err
          res.send("Ok") unless res.headersSent

      req.on "close", ->
        ws.end()

      ws.on "error", (e) ->
        #Send response
        res.status(500).send("File Error: #{e}")
