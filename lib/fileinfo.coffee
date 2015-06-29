
###
Stores File Info in sql DB
###

module.exports = (UploadModel) ->

  create: (id, finalLength, cb) ->
    UploadModel.create
      id: id
      final_length: finalLength
      created_on: Date.now()
      offset: 0
    .then (created) ->
      cb null, created

  save: (info, cb)->
    info.save().then ()->
      cb null

  load: (id, cb)->
    UploadModel.find({where: {id: id}}).then (found)->
      cb(null, found)

  remove: (info, cb)->
    info.destroy().then ()->
      cb(null)
