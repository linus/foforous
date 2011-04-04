http    = require 'http'
connect = require 'connect'
request = require 'request'

posts = []

exports.getPosts = getPosts = (config, next) ->
  request uri: "http://posterous.com/api/2/users/#{config.posterous.user}/sites/primary/posts/public?api_token=#{config.posterous.api_token}", (err, res, body) ->
    posts = JSON.parse body if body

    next err, posts

exports.routes = (config) ->
  page_size = config.page_size

  verifyPassword = (config) ->
    connect.basicAuth (user, password) ->
      user is config.user and password is config.password
    , config.realm

  (app) ->
    app.get '/update', verifyPassword(config)
    app.get '/update', (req, res, next) ->
      req.flash 'info', 'Login successful'

      res.render 'update'

    app.post '/update', verifyPassword(config)
    app.post '/update', (req, res, next) ->
      getPosts config, (err, newPosts) ->
        if err
          req.flash 'error', err.message
        else
          req.flash 'info', 'Updated!'
          posts = newPosts

        res.redirect '/'
  
    app.get '/', (req, res, next) ->
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
  
    app.get '/:slug', (req, res, next) ->
      post = posts.filter (post) -> post.slug is req.params.slug
      return res.send 404 if not post.length
  
      index = posts.indexOf post[0]
      first = Math.max(index - page_size / 2, 0)
      last  = Math.min(index + page_size / 2, posts.length)
  
      res.render 'posts',
        layout: not req.xhr
        locals:
          posts: posts[first...last]
