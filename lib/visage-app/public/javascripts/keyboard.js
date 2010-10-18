function gotoBuilder() {
    var uri = new URI('/builder')
    uri.go()
}

function gotoProfiles() {
    var uri = new URI('/profiles')
    uri.go()
}

function navigation() {

}

function moveUp() {
    if ( $('navigation') ) {
        var active    = $('navigation').getElement('.active')
        var previous  = active.getPrevious('.shortcut')

        if (previous) {
            active.toggleClass('active')
            previous.toggleClass('active')
        }
    }
}

function moveDown() {
    if ( $('navigation') ) {
        var active = $('navigation').getElement('.active')
        var next   = active.getNext('.shortcut')
        if (next) {
            active.toggleClass('active')
            next.toggleClass('active')
        }
    }
}

function select() {
    if ( $('navigation') ) {
        var active      = $('navigation').getElement('.active')
        var destination = active.getElement('a').get('href')
        var uri         = new URI(destination)
        uri.go()
    }
}

function back() {
    history.go(-1)
}

window.addEvent('domready', function() {

    var vKeyboard = new Keyboard();
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
        }
    });
});
