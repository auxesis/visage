sinatra-collectd
================

Web interface for viewing collectd stats. 

Also provides JSON interface onto collectd's RRD data.

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

 * nice scrollbars to specify start/end time. 
 * zoom + dynamic resize
 * axis labels
 * data profiles
 * config file
 * graph builder + profile creator
