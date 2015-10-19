
should = require('should')
http = require('http')
fs = require('fs')
path = require('path')
rimraf = require 'rimraf'
express = require('express')
One00 = require './1.0.0'

port = process.env.PORT || 3333
process.env.NODE_ENV = 'devel'
process.env.FILESDIR = path.join(__dirname, '_testfiles')
process.env.TUS_MAX_SIZE_IN_MEGAS = 1

# entry ...
describe "app", ->

  appModule = require(__dirname + '/../index')
  Db = require(__dirname + "/../lib/db")
  g = {}

  before (done) ->

    g.app = express()

    Db (err, db)->
      return done(err) if err
      appModule.initApp(g.app, db)

      g.server = g.app.listen port, (err) ->
        return done(err) if err
        done()

  after (done) ->
    rimraf.sync(process.env.FILESDIR)
    g.server.close()
    done()

  # run the rest of tests
  baseurl = "http://127.0.0.1:#{port}"

  # require('./uploads')(g.db, baseurl)
  One00(g.db, baseurl)
