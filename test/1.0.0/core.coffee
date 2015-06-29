
should = require('should')
fs = require('fs')
request = require('request').defaults({timeout: 5000})


module.exports = (g) ->


  it "shall upload first 512 bytes of sample file", (done) ->

    chunksize = 128

    _send = (curr) ->
      options =
        url: g.location
        method: 'PATCH',
        headers:
          'Content-Type': 'application/offset+octet-stream'
          'Content-Length': chunksize
          'upload-offset': curr
          'Tus-Resumable': '1.0.0'
      req = request options, (err, res, body) ->
        return done(err) if err

        res.statusCode.should.eql 204
        should.exist res.headers['upload-offset']
        res.headers['upload-offset'].should.eql (curr + chunksize).toString()
        if curr + chunksize >= 512
          done()
        else
          _send(curr+chunksize)

      req.write g.samplefile[curr..curr+chunksize-1]
      req.end()

    _send(0)


  it "shall return current offset of the partial uploaded file", (done) ->
    options =
      url: g.location
      method: 'HEAD',
      headers:
        'Tus-Resumable': '1.0.0'
    request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      should.exist res.headers['upload-offset']
      res.headers['upload-offset'].should.eql '512'
      ###
      The Server MUST prevent the client and/or proxies from caching the
      response by adding the Cache-Control: no-store header to the response.
      ###
      should.exist res.headers['cache-control']
      res.headers['cache-control'].should.eql 'no-store'
      done()


  it "must not PATCH when wrong content-type", (done) ->
    options =
      url: g.location
      method: 'PATCH',
      headers:
        'Content-Type': 'application/json'
        'Content-Length': g.samplefile.length - 512
        'upload-offset': 512
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      done()

    req.write g.samplefile[512..]
    req.end()


  it "must not PATCH when offset missing", (done) ->
    options =
      url: g.location
      method: 'PATCH',
      headers:
        'Content-Type': 'application/offset+octet-stream'
        'Content-Length': g.samplefile.length - 512
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      body.should.eql 'upload-offset header Required'
      done()

    req.write g.samplefile[512..]
    req.end()


  it "must not upload the rest of da file when offset wrong", (done) ->
    options =
      url: g.location
      method: 'PATCH',
      headers:
        'Content-Type': 'application/offset+octet-stream'
        'Content-Length': g.samplefile.length - 512
        'upload-offset': 'wrongoffset'
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 400
      body.should.eql 'upload-offset header Invalid'
      done()

    req.write g.samplefile[512..]
    req.end()


  it "must not PATCH when offset bigger then current", (done) ->
    options =
      url: g.location
      method: 'PATCH',
      headers:
        'Content-Type': 'application/offset+octet-stream'
        'Content-Length': g.samplefile.length - 512
        'upload-offset': 612
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 409
      body.should.eql 'Conflict'
      done()

    req.write g.samplefile[512..]
    req.end()


  it "shall upload the rest of da file", (done) ->
    options =
      url: g.location
      method: 'PATCH',
      headers:
        'Content-Type': 'application/offset+octet-stream'
        'Content-Length': g.samplefile.length - 512
        'upload-offset': 512
        'Tus-Resumable': '1.0.0'
    req = request options, (err, res, body) ->
      return done(err) if err

      ###
      The Server MUST acknowledge successful PATCH with 204 No Content status.
      It MUST include the Upload-Offset header containing the new offset.
      ###
      res.statusCode.should.eql 204
      should.exist res.headers['upload-offset']
      res.headers['upload-offset'].should.eql g.samplefile.length.toString()
      done()

    req.write g.samplefile[512..]
    req.end()


  it "shall return offset equal to file size", (done) ->
    options =
      url: g.location
      method: 'HEAD',
      headers:
        'Tus-Resumable': '1.0.0'
    request options, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      should.exist res.headers['upload-offset']
      res.headers['upload-offset'].should.eql g.samplefile.length.toString()
      filename = /https?:\/\/127.0.0.1:[0-9]*\/(.*)/g.exec(g.location)[1]
      filename = "#{process.env.FILESDIR}/#{filename}"
      fs.readFileSync(filename).toString().should.eql g.samplefile
      done()


  it "shall return actual file", (done) ->
    request.get g.location, (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      # res.headers['content-type'].should.eql 'plain/text'
      body.should.eql g.samplefile
      done()
