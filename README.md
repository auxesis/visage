visage
======

Web interface for viewing `collectd` statistics. 

Also provides JSON interface onto `collectd`'s RRD data.

Installing
----------

Freeze in dependencies:

    $ rake deps

Running
-------

For development: 

    $ gem install shotgun
    $ shotgun sinatra-collectd.rb

Testing 
-------

Run all cucumber features: 

    $ rake cucumber 

Specific features: 

    $ bin/cucumber --require features/ features/something.feature

TODO
----

 * create proper mootools class - DONE
 * switch to g.raphael - DONE
 * config file - DONE
 * data profiles - DONE
 * nice scrollbars to specify start/end time. 
 * zoom + dynamic resize
 * axis labels
 * graph builder + profile creator
