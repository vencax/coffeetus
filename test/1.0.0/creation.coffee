
should = require('should')
fs = require('fs')
request = require('request').defaults({timeout: 5000})


###
https://github.com/tus/tus-resumable-upload-protocol/blob/1.0/protocol.md#creation
###
module.exports = (addr, g) ->


  it "must return appropriate server info for OPTIONS req", (done) ->

    request
      url: "#{addr}#{g.base}/"
      method: 'OPTIONS',
      headers:
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 204
      body.should.eql ''
      should.exist res.headers['tus-version']
      res.headers['tus-version'].should.eql '1.0.0'
      should.exist res.headers['tus-extension']
      res.headers['tus-extension'].should.eql 'creation,termination'
      done()


  it "must not create a new file without Upload-Length header", (done) ->

    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      should.not.exist res.headers['location']
      done()

  it "must not create a new file for too big file", (done) ->

    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Tus-Resumable': '1.0.0'
        'Upload-Length': parseInt(process.env.TUS_MAX_SIZE_IN_MEGAS) * 1024 * 1024 * 2
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 413
      should.not.exist res.headers['location']
      done()


  it "must not create a new file with unsuported tus version", (done) ->

    req = request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Length': g.samplefile.length
        'Tus-Resumable': '1111.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 412
      body.should.eql 'Precondition Failed'
      should.not.exist res.headers['location']
      should.exist res.headers['tus-version']
      done()

    req.write '{}'
    req.end


  it "shall create a new file", (done) ->

    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Length': g.samplefile.length
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      should.exist res.headers['tus-resumable']
      g.location = res.headers['location']
      done()


  it "shall create a new file with custom filename", (done) ->
    fileName = 'customFileNNNName.txt'

    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(fileName).toString('base64')
        'Upload-Length': 123
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      done()

  fileName = "sub1/sub2/testfile1.txt"

  it "shall create a new file with custom filename in subfolder", (done) ->

    req = request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(fileName).toString('base64')
        'Upload-Length': g.samplefile2.length
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      g.locationWithPath = res.headers['location']
      done()


  it "must create an existing file again", (done) ->

    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(fileName).toString('base64')
        'Upload-Length': g.samplefile2.length
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      should.exist res.headers['tus-resumable']
      res.headers['location'].should.eql g.locationWithPath
      done()


  it "mustnot create a new file out of upload folder (usage ../..)", (done) ->
    badFileName = "../../testfile1.txt"
    request
      url: "#{addr}#{g.base}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(badFileName).toString('base64')
        'Upload-Length': 123
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      should.not.exist res.headers['location']
      done()
