http    = require 'http'
querystring = require 'querystring'
connect = require 'connect'
utils   = require 'connect/lib/utils'
request = require 'request'

data =
  site: null
  pages: []
  posts: []

authorization = null

posterousRequest = (params, config, next) ->
  authorization ?= new Buffer("#{config.posterous.email}:#{config.posterous.password}").toString('base64')

  if params.uri.substr(0, 7) isnt 'http://'
    params.uri = "http://posterous.com/api/2/users/#{config.posterous.user}/sites/primary/#{params.uri}?api_token=#{config.posterous.api_token}"

  params.headers = {} if not params.headers
  params.headers.authorization = "Basic #{authorization}"

  request params, (err, res, body) ->
    if 200 <= res.statusCode < 400
      result = JSON.parse(body)

    next(err, result)

exports.update = update =
  site: (config, next) ->
    posterousRequest {uri: ""}, config, (err, res) ->
      return next(err) if err

      data.site = res
      next(null, data.site)

  pages: (config, next) ->
    posterousRequest {uri: "pages"}, config, (err, res) ->
      return next(err) if err

      data.pages = res
      next(null, data.pages)

  posts: (config, next) ->
    posterousRequest {uri: "posts/public"}, config, (err, res) ->
      return next(err) if err

      data.posts = res
      next(null, data.posts)

  comments: (post, config, next) ->
    posterousRequest {uri: "posts/#{post}/comments"}, config, (err, res) ->
      return next(err) if err

      post = data.posts.filter -> @id is post
      return next(null, null) if not post.length

      index = data.posts.indexOf post[0]
      data.posts[index].comments = res
      next(null, res)

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
      user is config.posterous.email and password is config.posterous.password

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
        post = posts.filter -> @id is req.params.prev
        index = posts.indexOf post[0]
  
        first = Math.max(index - page_size, 0)
        last = index - 1
  
      if req.params.next
        post = posts.filter -> @id is req.params.next
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
          site: site
          posts: posts
          updated: new Date(posts[posts.length - 1].display_date)

    app.get '/:slug', (req, res, next) ->
      posts = data.posts
      post = posts.filter (post) -> post.slug is req.params.slug
      return res.send 404 if not post.length

      index = posts.indexOf post[0]
      first = Math.max(index - page_size / 2, 0)
      last  = Math.min(index + page_size / 2, posts.length)

      update.comments post[0].id, config, (err, comments) ->
        res.render 'posts',
          layout: not req.xhr
          locals:
            posts: posts[first...last]

    app.get '/:id/comments', (req, res, next) ->
      update.comments req.params.id, (err, comments) ->
        res.render 'posts/comments',
          layout: not req.xhr
          locals:
            comments: comments

    app.post '/:id/comments', (req, res, next) ->
      comment =
        "comment[name]": req.body.name
        "comment[email]": req.body.email
        "comment[body]": req.body.body

      posterousRequest {
          uri: "posts/#{req.params.id}/comments"
          method: "POST"
          body: querystring.stringify comment
        }, config, (err, comment) ->
          return next(err) if err
          return res.redirect("/#{req.params.id}/comments") if not req.xhr

          res.render 'posts/comment',
            layout: false
            locals:
              comment: comment
