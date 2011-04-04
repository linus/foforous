(function() {
  var fetch, scroll, scrollTo, scroller, viewPost;
  scroll = function(element, selector, direction) {
    var container, containerLeft;
    container = element.siblings(selector);
    containerLeft = container.position().left;
    if (parseInt(container.find(direction.filter).position().left) !== parseInt(containerLeft)) {
      return element.siblings(selector).animate({
        marginLeft: direction.sign + "=" + element.parent().width()
      }, 1500, "easeOutBounce");
    }
  };
  scroller = function(selector) {
    var directions;
    directions = {
      prev: {
        sign: "+",
        filter: "> :first-child"
      },
      next: {
        sign: "-",
        filter: "> :last-child"
      }
    };
    return function() {
      var $this, direction;
      $this = $(this);
      direction = $this.is(".prev") ? directions.prev : directions.next;
      scroll($this, selector, direction);
      return false;
    };
  };
  fetch = function(direction, $post) {
    var id, insertMethod;
    id = $post.attr("id").split("-").pop();
    insertMethod = direction === "prev" ? "insertBefore" : "insertAfter";
    return $.get("/?" + direction + "=" + id, function(data, status, req) {
      return $post[insertMethod]($("section#posts", data).html());
    });
  };
  viewPost = function(selector) {
    var $anchor, $next, $post, $prev;
    $post = $(selector);
    $prev = $post.prev();
    $next = $post.next();
    if ($prev.length > 0) {
      $("#container > a.prev").show().attr("href", $("header > h1 > a", $prev).attr("href"));
    } else {
      $("#container > a.prev").hide();
    }
    if ($next.length > 0) {
      $("#container > a.next").show().attr("href", $("header > h1 > a", $next).attr("href"));
    } else {
      $("#container > a.next").hide();
    }
    $anchor = $("header > h1 > a", selector);
    window.history.pushState({}, $anchor.text(), $anchor.attr("href"));
    return scrollTo(selector);
  };
  scrollTo = function(target) {
    return $("#container").scrollTo(target, 1500, {
      easing: "easeOutBounce",
      axis: "x"
    });
  };
  $("#container > a.prev, #container > a.next").live("click", function() {
    viewPost("#post-" + $(this).attr("href").slice(1));
    return false;
  });
  $("article > a.prev, article > a.next").live("click", scroller("ul.images"));
  $(document).keydown(function(e) {
    if (e.keyCode === 39) {
      return $("#container > a.next").click();
    } else if (e.keyCode === 37) {
      return $("#container > a.prev").click();
    }
  });
  $(function() {
    var $window, firstMove;
    $window = $(window);
    if (window.location.pathname !== "/") {
      viewPost("#post-" + window.location.pathname.slice(1));
    }
    (function() {
      var $updateForm, delayHide, hide, show;
      $updateForm = $('form#update');
      show = function() {
        $updateForm.show();
        return false;
      };
      hide = function() {
        $updateForm.hide();
        return false;
      };
      delayHide = function() {
        setTimeout(hide, 2000);
        return false;
      };
      $('header.main').mouseenter(show);
      $('header.main').mouseleave(delayHide);
      $updateForm.mouseenter(show);
      return $updateForm.mouseleave(delayHide);
    })();
    $('.notice', '#notices').hide().delay(100).fadeIn('fast').find('a.close').click(function() {
      $(this).parent('.notice').hide();
      return false;
    });
    firstMove = function() {
      $('.info', '#notices').delay(1000).fadeOut('fast');
      $('.warning', '#notices').delay(5000).fadeOut('fast');
      $('.error', '#notices').delay(10000).fadeOut('fast');
      $window.unbind('mousemove', firstMove);
      return $window.unbind('keydown', firstMove);
    };
    $window.bind('mousemove', firstMove);
    return $window.bind('keydown', firstMove);
  });
}).call(this);
