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

Check out [a demo](http://visage.unstated.net/nadia/cpu+load).

Installing
----------

On Ubuntu, to install dependencies run:

    $ sudo apt-get install -y librrd-ruby ruby rubygems

On CentOS, to install dependencies run:

    $ sudo yum install -y rrdtool ruby rubygems

Then install the app with:

    $ gem install visage-app


Running
-------

You can try out the application quickly with:

    $ visage start


Configuring
-----------

Config lives in several files under `config/`.

 * `profiles.yaml` - groups of graphs Visage is to display
 * `plugin-colors.yaml` - colors for specific plugins/plugin instances
 * `fallback-colors.yaml` - ordered list of fallback colors
 * `init.rb` - bootstrapping code, specifies collectd's RRD directory

`profiles.yaml` isn't setup by default, but you can copy `profiles.yaml.sample`
across and edit to taste. The plugins are in the format of
`plugin/plugin-instance`, with `plugins-instance` being optional.

If you don't specify a `plugin-instance` Visage will attempt to graph all plugin
instances under the specified `plugin`, e.g. `cpu-0` will display `cpu-idle`,
`cpu-interrupt`, `cpu-nice`, etc, whereas `cpu-0/cpu-wait` will only show
`cpu-wait`. You can also choose a specific group of plugin instances to graph,
with something like `cpu-0/cpu-system/cpu-user/cpu-wait`.

It should be pretty easy to deduce the config format from the existing file
(it's simple nested key-value data).

Make sure collectd's RRD directory is readable by whatever user the web server
is running as. You can specify where collectd's rrd directory is in `init.rb`,
with the `c['rrddir']` key.

Deploying
---------

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

Ubuntu users looking for Passenger packages should add John Ferlito's
[mod-passenger PPA](https://launchpad.net/~johnf-inodes/+archive/mod-passenger)
to their apt sources.

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

Specific features:

    $ bin/cucumber --require features/ features/something.feature

TODO
----

 * refactor tests to work on hosts other than my laptop
 * interface to build custom graph profiles
 * combine graphs from different hosts
 * detailed point-in-time data on hover
 * comment on time periods
 * view list of comments
