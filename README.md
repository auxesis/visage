Visage
======

Visage is a web interface for viewing [collectd](http://collectd.org) statistics.

It also provides a [JSON](http://json.org) interface onto `collectd`'s RRD data,
giving you an easy way to mash up the data.

Features
--------

 * renders graphs in the browser, and retrieves data asynchronously
 * interactive graph keys, to highlight lines and toggle line visibility
 * drop-down or mouse selection of timeframes (also rendered asynchronously)
 * JSON interface onto `collectd` RRDs

Here, have a graph:


![Something I prepared earlier.](http://farm2.static.flickr.com/1020/4730994504_c8c6fc9c18_z.jpg)


Or check out [a live demo](http://visage.unstated.net/nadia/cpu+load).

Installing
----------

N.B: Visage must be deployed on a machine where `collectd` stores its stats in RRD.

On Ubuntu, to install dependencies run:

    $ sudo apt-get install -y librrd-ruby ruby ruby-dev rubygems collectd

On CentOS, to install dependencies run:

    $ sudo yum install -y ruby-rrdtool ruby rubygems collectd

Then install the app with:

    $ gem install visage-app

Running
-------

You can try out Visage quickly with:

    $ visage start

Then paste the URL from the output into your browser.

If you get a `command not found` when running the above command (RubyGems likely
isn't on your PATH), try this instead:

    $ $(dirname $(dirname $(gem which visage-app)))/bin/visage start

Deploying
---------

Visage can be deployed on Apache with Passenger:

    $ sudo apt-get install libapache2-mod-passenger

Visage can attempt to generate an Apache vhost config for use with Passenger:

    $ visage genapache
    <VirtualHost *>
      ServerName ubuntu.localdomain
      ServerAdmin root@ubuntu.localdomain

      DocumentRoot /home/user/.gem/ruby/1.8/gems/visage-app-0.1.0/lib/visage-app/public

      <Directory "/home/user/.gem/ruby/1.8/gems/visage-app-0.1.0/lib/visage-app/public">
         Options FollowSymLinks Indexes
         AllowOverride None
         Order allow,deny
         Allow from all
       </Directory>
    </VirtualHost>

Copypasta this into your system's Apache config structure and tune to taste.

To do this on Debian/Ubuntu:

    $ sudo -s
    $ visage genapache > /etc/apache2/sites-enabled/visage
    $ a2dissite default
    $ service apache2 reload

Then head to your Apache instance and Visage will be up and running.

Configuring
-----------

On the off chance you need to tweak Visage's configuration, it lives in several files
under `lib/visage/config/`.

 * `plugin-colors.yaml` - colors for specific plugins/plugin instances
 * `fallback-colors.yaml` - ordered list of fallback colors
 * `init.rb` - bootstrapping code, specifies collectd's RRD directory

Make sure collectd's RRD directory is readable by whatever user the web server
is running as. You can specify where collectd's rrd directory is in `init.rb`,
with the `c['rrddir']` key.


Developing + testing
--------------------

Check out the code with:

    $ git clone git://github.com/auxesis/visage.git

Install the development dependencies with

    $ gem install shotgun rack-test rspec cucumber webrat

And run the app with:

    $ shotgun visage.rb

Create and install a new gem from the current source tree:

    $ rake install

Run all cucumber features:

    $ rake cucumber

TODO
----

 * make other lines slightly opaque when hovering over labels
 * detailed point-in-time data on hover (timestamp, value)
 * give graph profile an alternate private url
 * make notes/annotations on private url
 * include table of axis mappings + default y-axis heights for rendering
 * view metrics from multiple hosts on the same graph
