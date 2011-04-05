#!/usr/bin/env coffee

fs        = require 'fs'
util      = require 'util'
crypto    = require 'crypto'
path      = require 'path'
express   = require 'express'
csrf      = require 'express-csrf'
stylus    = require 'stylus'
posterous = require './posterous'
require './date.format'

exports.start = module.exports.start = (config) ->
  app = express.createServer()
  
  views  = path.join(__dirname, "..", config.views or 'views')
  client = path.join(__dirname, "..", config.client or 'client')
  public = path.join(__dirname, "..", config.public or 'public')
  
  app.set('views', views)
  app.set('view engine', 'jade')
  
  # This will be in the context of every view
  app.helpers
    config:
      googleAnalyticsId: config.googleAnalyticsId
  
  app.dynamicHelpers
    session: (req, res) ->
      req.session
  
    flash: (req, res) ->
      req.flash()
  
    csrf: csrf.token
  
    checksum: (req, res) ->
      cache = {}
      calculate = (file) ->
        contents = fs.readFileSync(path.join(public, file[1..]))
        crypto.createHash("md5").update(contents).digest("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
  
      (file) ->
        checksum = cache[file] or (cache[file] = calculate(file))
        file + "?" + checksum
  
    humanDate: (req, res) ->
      (date) ->
        diff = new Date() - date
        second = 1000
        minute = 60 * second
        hour = 60 * minute
        day = 24 * hour
        switch diff
          when diff < minute then return Math.floor(diff / second) + ' sekunder sedan'
          when diff < hour then return Math.floor(diff / minute) + ' minuter sedan'
          when diff < day then return 'idag, kl ' + date.format('HH:MM')
          when diff < 2 * day then return 'igår, kl ' + date.format('HH:MM')
          else return date.format('yyyy-mm-dd HH:MM')
  
  app.use express.logger()
  app.use express.cookieParser()
  app.use express.session(secret: config.posterous.password)
  app.use express.bodyParser()
  app.use csrf.check()
  app.use express.favicon(path.join(public, "favicon.ico"))
  
  app.configure 'development', ->
    app.use stylus.middleware(src: path.join(views, 'styles'), dest: public)
    app.use express.compiler(src: client, dest: public, enable: ['coffeescript'])
    app.use express.static(public)
    app.use express.router(posterous.routes(config))
    app.use express.errorHandler(showStack: true, dumpExceptions: true)
  
  app.configure 'production', ->
    app.use express.static(public, maxAge: 365 * 24 * 60 * 60)
    app.use express.router(posterous.routes(config))
    app.use express.errorHandler()
  
  app.on 'close', ->
    util.error('Server stopped.')

  posterous.update.all config, (err) ->
    return console.error(err.message) if err
  
    app.listen(config.port or 3000)
    util.error('Server started.')
