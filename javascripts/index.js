window.addEvent('load', function() {
    var debianInstallerSlider  = new Fx.Slide('debian-installer', {'duration': 300, 'transition': Fx.Transitions.Sine});

    /* the rhell installer instructions slider/toggler combo */
    var rhelInstallerSlider  = new Fx.Slide('rhel-installer', {'duration': 300});
    var installerToggler = $('installer-toggler');

    installerToggler.addEvent('click', function(e) {
        e.stop();
        rhelInstallerSlider.toggle();
        debianInstallerSlider.toggle();

        if (installerToggler.get('html').contains('RHEL')) {
            installerToggler.set('html', 'Nah, just kidding - I use <a href="#debian-installer">Debian/Ubuntu</a>.');
        } else {
            installerToggler.set('html', 'Hey wait a sec! I use <a href="#rhel-installer">RHEL/CentOS</a>!');
        }
    });

    rhelInstallerSlider.hide();

    /* the path hack slider/toggler combo */
    var pathHackSlider  = new Fx.Slide('rubygems-path-hack', {'duration': 300});
    var pathHackToggler = $('rubygems-path-hack-toggler');

    pathHackToggler.addEvent('click', function(e) {
      e.stop();
      pathHackSlider.slideIn();
    });

    pathHackSlider.hide();

    $$('div#nav a').each(function(element) {
        element.addEvent('click', function(e) {
            e.stop()
            var href     = element.get('href');
            var section  = href.substring(1);
            var scroller = new Fx.Scroll(window)

            scroller.toElement(section).chain(function() { parent.location.hash = href; });
        });
    });
});
