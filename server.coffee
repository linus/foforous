#!/usr/bin/env coffee

config = require('config').config
fofo   = require('./lib/fofo')

fofo.start(config)
