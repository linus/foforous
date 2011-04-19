scroll = (element, selector, direction) ->
  container = element.siblings(selector)
  containerLeft = container.position().left
  if parseInt(container.find(direction.filter).position().left) isnt parseInt(containerLeft)
    element.siblings(selector).animate
      marginLeft: direction.sign + "=" + element.parent().width()
    , 1500, "easeOutBounce"

scroller = (selector) ->
  directions =
    prev:
      sign: "+", filter: "> :first-child"
    next:
      sign: "-", filter: "> :last-child"

  ->
    $this = $(this)
    direction = if $this.is(".prev") then directions.prev else directions.next
    scroll $this, selector, direction
    return false

fetch = (direction, $post) ->
  id = $post.attr("id").split("-").pop()
  insertMethod = if direction is "prev" then "insertBefore" else "insertAfter"
  $.get "/?#{direction}=#{id}", (data, status, req) ->
    $post[insertMethod] $("section#posts", data).html()

window.onpopstate = (event) ->
  viewPost(event.state.href, false) if event.state

loadImages = (post) ->
  $("img[data-src]", post).each (i, img) ->
    $img = $(img)
    $img
      .hide()
      .attr("src", $img.attr("data-src"))
      .removeAttr("data-src")
      .fadeIn()

viewPost = (url, pushState) ->
  if url is "/"
    $post = $("section#posts > article:first")
  else
    $post = $("#post-#{url[1..]}")

  loadImages($post)

  $prev = $post.prev()
  $next = $post.next()

  if $prev.length > 0
    $("#container > a.prev").show().attr("href", $("header > h1 > a", $prev).attr("href"))
  else
    $("#container > a.prev").hide()
  if $next.length > 0
    $("#container > a.next").show().attr("href", $("header > h1 > a", $next).attr("href"))
  else
    $("#container > a.next").hide()

  $anchor = $("header > h1 > a", $post)
  title = $anchor.text()
  href = $anchor.attr("href")

  if pushState
    window.history.pushState {title: title, href: href}, title, href

  scrollTo $post

scrollTo = (target) ->
  $("#container").scrollTo target, 1500,
    easing: "easeOutBounce"
    axis: "x"

$("#container > a.prev, #container > a.next").live "click", ->
  viewPost($(this).attr("href"), true)
  return false

$("article > a.prev, article > a.next").live "click", scroller "ul.images"

$(document).keydown (e) ->
  if e.keyCode is 39
    $("#container > a.next").click()
  else if e.keyCode is 37
    $("#container > a.prev").click()

$ ->
  $window = $(window)

  $("header.main").delay(500).animate
    marginBottom: 0
  , 1000, -> viewPost(window.location.pathname, false)

  # Update button
  do ->
    $updateForm = $('form#update')
    show = ->
      $updateForm.show()
      false
    hide = ->
      $updateForm.hide()
      false
    delayHide = ->
      setTimeout hide, 2000
      false

    $('header.main').mouseenter show
    $('header.main').mouseleave delayHide

    $updateForm.mouseenter show
    $updateForm.mouseleave delayHide

  # Notices
  $('.notice', '#notices').hide().delay(100).fadeIn('fast')
    .find('a.close').click ->
      $(this).parent('.notice').hide()
      false

  # Don't remove notices until user touches inputs
  firstMove = ->
    $('.info', '#notices').delay(1000).fadeOut('fast')
    $('.warning', '#notices').delay(5000).fadeOut('fast')
    $('.error', '#notices').delay(10000).fadeOut('fast')
    $window.unbind 'mousemove', firstMove
    $window.unbind 'keydown', firstMove

  $window.bind 'mousemove', firstMove
  $window.bind 'keydown', firstMove

  # Post comments

  $("form.post-comment").submit (e) ->
    $form = $(this)
    $.post this.action, $form.serialize(), (response) =>
      $form.parents('.post').find('ul.comments').append(response)
    e.preventDefault()
