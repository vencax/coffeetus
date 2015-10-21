
should = require('should')
fs = require('fs')
path = require 'path'
request = require('request').defaults({timeout: 5000})

###
https://github.com/tus/tus-resumable-upload-protocol/blob/1.0/protocol.md#termination
###
module.exports = (addr, g) ->

  it "must not terminate not existing file", (done) ->

    request
      url: "#{addr}/iamnotexists"
      method: 'DELETE',
      headers:
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 404
      should.not.exist res.headers['location']
      done()


  it "shall terminate a samplefile 2", (done) ->

    req = request
      url: "#{g.locationWithPath}"
      method: 'DELETE',
      headers:
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 204
      should.exist res.headers['tus-resumable']
      fs.existsSync(path.join process.env.FILESDIR, g.locationWithPath).should.eql false
      done()


  it "must not terminate a samplefile 2 (it is already gone)", (done) ->

    request
      url: "#{g.locationWithPath}"
      method: 'DELETE',
      headers:
        'Tus-Resumable': '1.0.0'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 404
      should.not.exist res.headers['location']
      done()
