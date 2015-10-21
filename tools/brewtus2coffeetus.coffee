
glob = require 'glob'
path = require 'path'
fs = require 'fs'
Db = require(__dirname + "/../lib/db")

Db (err, db)->
  return console.log(err) if err

  glob "**/*.json", {cwd: process.env.FILESDIR}, (err, files) ->

    for f in files
      solveFile(f, db)


solveFile = (file, db)->
  # cut off .json
  fileId = file.slice(0, - ".json".length)

  fPath = path.join process.env.FILESDIR, file
  # read adn parse the info file
  info = JSON.parse(fs.readFileSync(fPath))

  db.models.upload.find({where: {id: fileId}}).then (found)->

    if not found
      state = 0
      if info.offset == info.finalLength
        state = 1

      db.models.upload.create
        id: fileId
        final_length: info.finalLength
        created_on: info.createdOn
        offset: info.offset
        received: info.bytesReceived
        state: state
      .then (created) ->
        console.log "#{file}: OK"
      .catch (err) ->
        console.log "Creation of #{file}: #{err}"
