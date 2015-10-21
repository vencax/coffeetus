
Core = require './core'
Creation = require './creation'
Termination = require './termination'


module.exports = (g, addr) ->

  g.location = null
  g.samplefile = [1 .. 1000].join(',')
  g.samplefile2 = [1001 .. 2014].join('-')

  Creation(addr, g)
  Core(g)
  Termination(addr, g)
