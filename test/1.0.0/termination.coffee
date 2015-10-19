
should = require('should')
fs = require('fs')
request = require('request').defaults({timeout: 5000})


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
      done()
