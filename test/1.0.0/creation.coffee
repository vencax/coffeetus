
should = require('should')
fs = require('fs')
request = require('request').defaults({timeout: 5000})


module.exports = (addr, g) ->


  it "must return appropriate server info for OPTIONS req", (done) ->
    options =
      url: "#{addr}/"
      method: 'OPTIONS',
      headers:
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 204
      body.should.eql ''
      should.exist res.headers['tus-version']
      res.headers['tus-version'].should.eql '1.0.0'
      should.exist res.headers['tus-extension']
      res.headers['tus-extension'].should.eql 'creation,termination'
      done()


  it "must not create a new file without Upload-Length header", (done) ->
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Tus-Resumable': '1.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      should.not.exist res.headers['location']
      done()

    req.end


  it "must not create a new file with unsuported tus version", (done) ->
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Length': g.samplefile.length
        'Tus-Resumable': '1111.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 412
      body.should.eql 'Precondition Failed'
      should.not.exist res.headers['location']
      should.exist res.headers['tus-version']
      done()

    req.write '{}'
    req.end


  it "shall create a new file", (done) ->
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Length': g.samplefile.length
        'Tus-Resumable': '1.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      should.exist res.headers['tus-resumable']
      g.location = res.headers['location']
      done()
    req.end


  it "shall create a new file with custom filename", (done) ->
    fileName = 'customFileNNNName.txt'
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(fileName).toString('base64')
        'Upload-Length': 123
        'Tus-Resumable': '1.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      done()
    req.end


  it "shall create a new file with custom filename in subfolder", (done) ->
    fileName = "sub1/sub2/testfile1.txt"
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(fileName).toString('base64')
        'Upload-Length': g.samplefile2.length
        'Tus-Resumable': '1.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 201
      should.exist res.headers['location']
      g.locationWithPath = res.headers['location']
      done()
    req.end


  it "mustnot create a new file out of upload folder (usage ../..)", (done) ->
    badFileName = "../../testfile1.txt"
    options =
      url: "#{addr}/"
      method: 'POST',
      headers:
        'Content-Type': 'application/json'
        'Upload-Metadata': 'filename ' + new Buffer(badFileName).toString('base64')
        'Upload-Length': 123
        'Tus-Resumable': '1.0.0'

    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      should.not.exist res.headers['location']
      done()
    req.end
