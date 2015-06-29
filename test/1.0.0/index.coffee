
Core = require './core'
Creation = require './creation'


module.exports = (db, addr) ->

  g =
    location: null
    samplefile: [1 .. 1000].join(',')
    samplefile2: [1001 .. 2014].join('-')

  Creation(addr, g)
  Core(g)
