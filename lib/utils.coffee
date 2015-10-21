
uuid = require "node-uuid"
sanitize = require "sanitize-filename"


exports.parseMetadata = (req) ->
  metas = {}
  if req.headers["upload-metadata"] != undefined
    for m in req.headers["upload-metadata"].split(",")
      parts = m.split(" ")
      metas[parts[0]] = (new Buffer(parts[1], 'base64')).toString()
  return metas


# creates name of the created file
exports.getFileId = (metas) ->
  if metas.filename?
    parts = metas.filename.split('/')
    for p in parts
      p = sanitize(p)
    return parts.join('/')
  else
    return uuid.v1()


exports.getFileUrl = (fileId, req) ->
  if req.baseUrl == '/'
    return "/#{fileId}"
  else
    return "#{req.baseUrl}/#{fileId}"
