http    = require 'http'
connect = require 'connect'
utils   = require 'connect/lib/utils'
request = require 'request'

data =
  site: null
  pages: []
  posts: []

authorization = null

posterousRequest = (part, config, next) ->
  authorization ?= new Buffer("#{config.posterous.email}:#{config.posterous.password}").toString('base64')

  request
    uri: "http://posterous.com/api/2/users/#{config.posterous.user}/sites/primary/#{part}?api_token=#{config.posterous.api_token}"
    headers:
      authorization: "Basic #{authorization}"
    , (err, res, body) ->
      if 200 <= res.statusCode < 400
        result = JSON.parse(body)

      next(err, result)

exports.update = update =
  site: (config, next) ->
    posterousRequest "", config, (err, res) ->
      return next(err) if err

      data.site = res
      next(null, data.site)

  pages: (config, next) ->
    posterousRequest "pages", config, (err, res) ->
      return next(err) if err

      data.pages = res
      next(null, data.pages)

  posts: (config, next) ->
    posterousRequest "posts/public", config, (err, res) ->
      return next(err) if err

      data.posts = res
      next(null, data.posts)

  all: (config, next) ->
    update.site config, (err, newSite) ->
      return next(err) if err
  
      update.pages config, (err, newPages) ->
        return next(err) if err
  
        update.posts config, (err, newPosts) ->
          return next(err) if err
  
          next(null, data)
   
exports.routes = (config) ->
  page_size = config.page_size

  verifyPassword = (config) ->
    connect.basicAuth (user, password) ->
      user is config.posterous.user and password is config.posterous.password

  (app) ->
    app.get '/update', verifyPassword(config)
    app.get '/update', (req, res, next) ->
      req.flash 'info', 'Login successful'

      res.render 'update'

    app.post '/update', verifyPassword(config)
    app.post '/update', (req, res, next) ->
      type = req.params.type or "all"
      return utils.badRequest(res) if type not of update

      update[type] config, (err, newPosts) ->
        if err
          req.flash 'error', err.message
        else
          req.flash 'info', 'Updated!'

        res.redirect '/'
  
    app.get '/', (req, res, next) ->
      posts = data.posts

      page = req.params.page or 1
      first = (page - 1) * page_size
      last = page * page_size
  
      if req.params.prev
        post = posts.filter (post) -> post.id is req.params.prev
        index = posts.indexOf post[0]
  
        first = Math.max(index - page_size, 0)
        last = index - 1
  
      if req.params.next
        post = posts.filter (post) -> post.id is req.params.next
        index = posts.indexOf post[0]
  
        first = index + 1
        last = Math.min(index + page_size, posts.lengh)
  
      res.render 'posts',
        layout: not req.xhr
        locals:
          posts: posts[first...last]
  
    app.get '/feed.atom', (req, res, next) ->
      site = data.site
      posts = data.posts[0...page_size]

      res.contentType('application/atom+xml')
      res.render 'atom',
        layout: false
        locals:
          site: data.site
          posts: posts
          updated: new Date(posts[posts.length - 1].display_date)

    app.get '/:slug', (req, res, next) ->
      posts = data.posts
      post = posts.filter (post) -> post.slug is req.params.slug
      return res.send 404 if not post.length
  
      index = posts.indexOf post[0]
      first = Math.max(index - page_size / 2, 0)
      last  = Math.min(index + page_size / 2, posts.length)
  
      res.render 'posts',
        layout: not req.xhr
        locals:
          posts: posts[first...last]

