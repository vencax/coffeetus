
fs = require "fs"
path = require "path"
mkdirp = require "mkdirp"
touch = require "touch"

FileInfo = require "./fileinfo"
Utils = require "./utils"

filesDir = process.env.FILESDIR || path.join(__dirname, 'files')
MAX_SIZE = parseInt(process.env.TUS_MAX_SIZE_IN_MEGAS) * 1024 * 1024 || null

if not fs.existsSync(filesDir)
  fs.mkdirSync(filesDir)

supportedVersions = [
  '1.0.0'
]


module.exports = (UploadModel) ->

  _fileInfo = FileInfo(UploadModel)

  getInfo: (file, cb) ->
    _fileInfo.load file, (err, fleInfo) ->
      return cb(err) if err
      return cb(null, null) if not fleInfo
      fleInfo = fleInfo.toJSON()
      fleInfo.filepath = path.join filesDir, file
      cb(null, fleInfo)


  #GET MUST return Content-Length == Final-Length
  getFile: (req, res, next) ->
    return res.status(404).send("Not Found") unless req.params.id?

    _fileInfo.load req.params.id, (err, fleInfo)->
      return res.status(400).send(err) if err
      return res.status(404).send("Not Found") if not fleInfo

      if fleInfo.offset != fleInfo.final_length
        return res.status(404).send("Not Found")

      res.setHeader "Content-Length", fleInfo.final_length
      stream = fs.createReadStream(path.join(filesDir, req.params.id))
      stream.pipe(res)


  #Implements 6.1. File Creation
  createFile: (req, res, next) ->

    if req.headers["upload-length"] == undefined
      return res.status(400).send("upload-length Required")

    uploadLength = parseInt req.headers["upload-length"]

    #The value MUST be a non-negative integer.
    if isNaN(uploadLength) || uploadLength < 0
      return res.status(400).send("upload-length Must be Non-Negative integer")

    if MAX_SIZE and uploadLength > MAX_SIZE
      return res.status(413).send("Request Entity Too Large")

    metadata = Utils.parseMetadata(req)

    #generate fileId
    fileId = Utils.getFileId(metadata)

    if fileId.indexOf('..') >= 0
      return res.status(400).send("Bad fileName")

    _finishReq = ()->
      _fileInfo.create fileId, uploadLength, (err, fileInfo)->
        return res.status(400).send(err) if err

        fileAbs = path.join(filesDir, fileId)
        folder = path.dirname(fileAbs)
        mkdirp.sync folder unless fs.existsSync folder
        touch fileAbs, {}, (err) ->
          return res.status(400).send(err) if err

          location = Utils.getFileUrl(fileId, req)
          res.setHeader "Location", location
          res.setHeader "tus-resumable", "1.0.0"
          res.status(201).send("Created")


    _fileInfo.load fileId, (err, info)->
      return res.status(400).send(err) if err

      if info
        _fileInfo.remove info, ()->
          return _finishReq()
      else
        _finishReq()


  #Implements 5.3.1. HEAD
  headFile: (req, res, next) ->
    return res.status(404).send("Not Found") unless req.params.id

    _fileInfo.load req.params.id, (err, info)->
      return res.status(400).send(err) if err
      return res.status(404).send(err) if not info

      res.setHeader "upload-offset", info.offset
      res.setHeader "cache-control", "no-store"
      res.setHeader "tus-resumable", "1.0.0"
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
    unless req.headers["upload-offset"]?
      return res.status(400).send("upload-offset header Required")

    #The value MUST be an integer that is 0 or larger
    offsetIn = parseInt req.headers["upload-offset"]
    if isNaN(offsetIn) or offsetIn < 0
      return res.status(400).send("upload-offset header Invalid")

    unless req.headers["content-length"]?
      return res.status(400).send("Content-Length Required")

    contentLength = parseInt req.headers["content-length"]
    if isNaN(contentLength) or contentLength < 1
      return res.status(400).send("Invalid Content-Length")

    _fileInfo.load req.params.id, (err, info)->
      return res.status(400).send(err) if err
      return res.status(404).send(err) if not info

      return res.status(409).send("Conflict") if offsetIn > info.offset

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
          unless res.headersSent
            res.setHeader "Upload-Offset", info.offset
            res.setHeader "tus-resumable", "1.0.0"
            res.status(204).end()

      req.on "close", ->
        ws.end()

      ws.on "error", (e) ->
        #Send response
        res.status(500).send("File Error: #{e}")


  checkVersion: (req, res, next) ->
    header = req.headers["tus-resumable"]
    if header == undefined or header not in supportedVersions
      res.setHeader "Tus-Version", supportedVersions.join(',')
      return res.status(412).send("Precondition Failed")
    next()


  terminate: (req, res, next) ->
    return res.status(404).send("Not Found") unless req.params.id

    _fileInfo.load req.params.id, (err, info)->
      return res.status(400).send(err) if err
      return res.status(404).send('File not found') if not info

      _fileInfo.remove info, (err)->
        filePath = path.join(filesDir, req.params.id)
        fs.unlink filePath, (err)->
          return res.status(400).send(err) if err

          res.setHeader "Tus-Resumable", "1.0.0"
          return res.status(204).end()


  serverInfo: (req, res, next) ->
    res.setHeader "Tus-Version", supportedVersions.join(',')
    res.setHeader "Tus-Resumable", "1.0.0"
    res.setHeader "Tus-Extension", "creation,termination"
    res.setHeader("Tus-Max-Size", MAX_SIZE) if MAX_SIZE
    return res.status(204).end()
