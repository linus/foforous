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

viewPost = (selector) ->
  $post = $(selector)
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

  $anchor = $("header > h1 > a", selector)
  window.history.pushState {}, $anchor.text(), $anchor.attr("href")

  scrollTo selector

scrollTo = (target) ->
  $("#container").scrollTo target, 1500,
    easing: "easeOutBounce"
    axis: "x"

$("#container > a.prev, #container > a.next").live "click", ->
  viewPost "#post-" + $(this).attr("href")[1..]
  return false

$("article > a.prev, article > a.next").live "click", scroller "ul.images"

$(document).keydown (e) ->
  if e.keyCode is 39
    $("#container > a.next").click()
  else if e.keyCode is 37
    $("#container > a.prev").click()

$ ->
  $window = $(window)

  if window.location.pathname isnt "/"
    viewPost "#post-#{window.location.pathname[1..]}"

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

  firstMove = ->
    $('.info', '#notices').delay(1000).fadeOut('fast')
    $('.warning', '#notices').delay(5000).fadeOut('fast')
    $('.error', '#notices').delay(10000).fadeOut('fast')
    $window.unbind 'mousemove', firstMove
    $window.unbind 'keydown', firstMove

  $window.bind 'mousemove', firstMove
  $window.bind 'keydown', firstMove
