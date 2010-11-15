"use strict";

var mask;

function checkForInput(e) {
  var element;

  if (e.target) {
    element = e.target;
  }
  else if (e.srcElement) {
    element = e.srcElement;
  }

  // 3 == TEXT_NODE
  if (element.nodeType == 3) {
    element = element.parentNode;
  }

  if (element.tagName == 'INPUT' || element.tagName == 'TEXTAREA') {
    return true;
  }

  return false;
}


function gotoBuilder(e) {
    if (checkForInput(e)) {
      return;
    }

    var uri = new URI('/builder');
    uri.go();
}

function gotoProfiles(e) {
    if (checkForInput(e)) {
      return;
    }
    var uri = new URI('/profiles');
    uri.go();
}

function moveUp(e) {
    if (checkForInput(e)) {
      return;
    }
    if ( $('navigation') ) {
        var active    = $('navigation').getElement('.active');
        var previous  = active.getPrevious('.shortcut');

        if (previous) {
            var previousY = previous.getPosition().y,
                windowY   = window.getSize().y;

            if (previousY > windowY) {
                var scroller = new Fx.Scroll(window, {duration: 10});
                scroller.toElement(previous);
            }

            active.toggleClass('active');
            previous.toggleClass('active');
        }
    }
}

function moveDown(e) {
    if (checkForInput(e)) {
      return;
    }
    if ( $('navigation') ) {
        var active = $('navigation').getElement('.active');
        var next   = active.getNext('.shortcut');
        if (next) {
            var nextY   = next.getPosition().y,
                windowY = window.getSize().y;

            if (nextY > windowY) {
                var scroller = new Fx.Scroll(window, {duration: 10});
                scroller.toElement(next);
            }

            active.toggleClass('active');
            next.toggleClass('active');
        }
    }
}

function select(e) {
    if (checkForInput(e)) {
      return;
    }
    if ( $('navigation') ) {
        var active      = $('navigation').getElement('.active');
        var destination = active.getElement('a').get('href');
        var uri         = new URI(destination);
        uri.go();
    }
}

function back(e) {
    if (checkForInput(e)) {
      return;
    }
    history.go(-1);
}

function help(e) {
    if (checkForInput(e)) {
      return;
    }
    mask.toggle();;
}

window.addEvent('domready', function() {
    /* bindings */
    var vKeyboard = new Keyboard({defaultEventType: 'keydown'});
    vKeyboard.addShortcuts({
        'builder': {
            'keys':        'c',
            'description': 'Go to the builder',
            'handler':     gotoBuilder
        },
        'profiles': {
            'keys':        'g+i',
            'description': 'Go to the list of profiles',
            'handler':     gotoProfiles
        },
        'up': {
            'keys':        'k',
            'description': 'Move cursor up',
            'handler':     moveUp
        },
        'down': {
            'keys':        'j',
            'description': 'Move cursor down',
            'handler':     moveDown
        },
        'select': {
            'keys':        'enter',
            'description': 'Select the element',
            'handler':     select
        },
        'back': {
            'keys':        'u',
            'description': 'Go to previous location',
            'handler':     back
        },
        'help': {
            'keys':        'h',
            'description': 'Display a list of shortcuts',
            'handler':     help
        }
    });

    /* Shortcuts cheat sheet */
    mask = new Mask('shortcuts', {
        hideOnClick: true,
        onHide: function() {
            shortcutsContainer.hide()
        },
        onShow: function() {
            var offset = document.body.getScroll().y + 100;
            shortcutsContainer.setStyle('top', offset);
            shortcutsContainer.show();
        }
    });

    var shortcutsContainer = new Element('div', {
        'id': 'shortcuts'
    });

    var rows = [];
    vKeyboard.getShortcuts().each(function(shortcut) {
        rows.push([shortcut.keys, shortcut.description]);
    });
    var table = new HtmlTable({
        headers: ['Keys', 'Description'],
        rows:    rows
    });

    shortcutsContainer.hide();
    shortcutsContainer.grab(table);
    document.body.grab(shortcutsContainer, 'top');

    var shortcutsLink = new Element('a', {
        'html': 'Shortcuts',
        'href': '#',
        'events': {
            'click': function() {
                help()
            }
        }
    });
    var footer = $('footer');
    footer.set('html', footer.get('html') + ' | ');
    $('footer').grab(shortcutsLink);

});
