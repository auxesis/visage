Visage
======

Visage is a web interface for viewing [collectd](http://collectd.org) statistics.

It also provides a [JSON](http://json.org) interface onto `collectd`'s RRD data,
giving you an easy way to mash up the data.

Features
--------

 * Renders graphs in the browser with SVG, and retrieves data asynchronously
 * Easy interface for building, ordering, and sharing collections of graphs
 * Interactive graph elements - toggle line visibility, inspect exact point-in-time data
 * Drop-down or mouse selection of timeframes
 * JSON interface onto collectd RRDs
 * Support for FLUSH using either collectd's rrdtool plugin, or rrdcached

Here, have a graph:

![Something I prepared earlier - Visage 3.0 graph.](http://farm9.staticflickr.com/8234/8526570663_1d2479407f_c.jpg)

Installing
----------

N.B: Visage must be deployed on a machine where `collectd` stores its stats in RRD.

### Ubuntu ###

On Ubuntu, to install dependencies run:

``` bash
sudo apt-get install -y build-essential librrd-ruby ruby ruby-dev rubygems collectd
```

Then install the app with:

``` bash
gem install visage-app
```

### CentOS/RHEL ###

#### CentOS/RHEL 5 ####
Visage uses [yajl-ruby](https://github.com/brianmario/yajl-ruby) to work with
JSON, which requires Ruby >= 1.8.6. CentOS/RHEL 5 ship with Ruby 1.8.5, so you
will need to use [Ruby Enterprise Edition](http://www.rubyenterpriseedition.com/).

[Endpoint](http://endpoint.com) provide packages for REE and a [Yum repository](https://packages.endpoint.com/)
to ease installation.

Follow the above instructions for installing REE, and then run:

``` bash
sudo yum install -y librrd-dev ruby rubygems collectd
gem install librrd
```

Then install the app with:

``` bash
gem install visage-app
```

#### CentOS/RHEL 6+ ####

On CentOS 6, to install dependencies run:

``` bash
sudo yum install -y ruby-RRDtool ruby ruby-devel rubygems collectd
```

Then install the app with:

``` bash
gem install visage-app
```

### Mac OS X ###

Visage is not supported on Mac OS X, as RRDtool is a pain in the arse on that
platform. It's highly recommended you use [Vagrant](http://vagrantup.com/) to
fire up an Ubuntu box to run Visage.


Running
-------

You can try out Visage quickly with:

``` bash
visage-app start
```

Then paste the URL from the output into your browser.

If you get a `command not found` when running the above command (RubyGems likely
isn't on your PATH), try this instead:

``` bash
$(dirname $(dirname $(gem which visage-app)))/bin/visage-app start
```

Deploying
---------

Visage can be deployed easily on Apache with Passenger:

``` bash
sudo apt-get install libapache2-mod-passenger
```

Visage can attempt to generate an Apache vhost config for use with Passenger:

``` bash
$ visage-app genapache
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
```

Copypasta this into your system's Apache config structure and tune to taste.

To do this on Debian/Ubuntu:

``` bash
sudo -s
visage-app genapache > /etc/apache2/sites-available/visage
a2ensite visage
a2dissite default
service apache2 reload
```

Then visit your Apache instance in a browser, and Visage will be up and running.

Configuring
-----------

Visage looks for some environment variables when starting up:

  * `CONFIG_PATH`, an entry on the configuration file search path.
  * `TYPES`, the location of collectd's `types.db`
  * `RRDDIR`, the location of collectd's RRDs.
  * `COLLECTDSOCK`, the location of collectd's Unix socket.
  * `RRDCACHEDSOCK`, the location of rrdcached's Unix socket.
  * `VISAGE_DATA_BACKEND`, which storage backend to retrieve data from.

Visage has a configuration search path which can be used for overriding
individual files. By default it has one entry: `$VISAGE_ROOT/lib/visage/config/`.
You can set the `CONFIG_PATH` environment variable to add another directory to
the config load path. This directory will be searched when loading up
configuration files:

``` bash
CONFIG_PATH=/var/lib/visage visage-app start
```

This is especially useful when you want to deploy + run Visage from an installed
gem with Passenger. e.g.

```
<VirtualHost *:80>
  ServerName monitoring.example.org
  ServerAdmin me@example.org

  SetEnv CONFIG_PATH /var/lib/visage
  SetEnv RRDDIR /opt/collectd/var/lib/collectd

  DocumentRoot /var/lib/gems/1.8/gems/visage-app-0.3.0/lib/visage/public
  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>

  LogFormat "%h %l %u %t \"%r\" %>s %b" common
  CustomLog /var/log/apache2/access.log common
</VirtualHost>
```

Also to keep in mind when deploying with Passenger, the `CONFIG_PATH` directory
and its files need to have the correct ownership:

``` bash
chown nobody:nogroup -R /var/lib/visage
```

Developing + testing
--------------------

Check out the code:

``` bash
git clone git://github.com/auxesis/visage.git
```

Install the development dependencies:

``` bash
bundle
```

Run all the cukes:

``` bash
rake
```

Visage tests should pass every time. [Travis](https://travis-ci.org/auxesis/visage) says the current Visage is ![build status](https://travis-ci.org/auxesis/visage.png?branch=master).

Run the app with:

``` bash
VISAGE_DATA_BACKEND=Mock bundle exec shotgun lib/visage-app/config.ru -p 9292 -o 0.0.0.0 --server thin
```

Visage ships a Mock data backend, so you can test without needing a real instance of collectd writing data with the RRDtool plugin. Per the above example, you can enable it by specifying the `VISAGE_DATA_BACKEND=Mock` environment variable on the command line.

To create and install a new gem from the current source tree:

``` bash
rake build
```

Releasing
---------

1. Bump the version in `lib/visage-app/version.rb`
2. Add an entry to `CHANGELOG.md`
3. `git commit` everything.
4. Build the gem with `rake build`
5. Push the gem to RubyGems.org with `rake push`

Licencing
---------

Visage is MIT licensed.

Visage is distributed with Highcharts. Torstein Hønsi has kindly granted
permission to distribute Highcharts under the GPLv2 as part of Visage.

If you ever need an excellent JavaScript charting library, please consider
purchasing a [commercial license](http://highcharts.com/license) for
Highcharts.

Support
-------

 * Post to [the mailing list](https://groups.google.com/forum/?fromgroups=#!forum/visage-app).
 * Ping [@auxesis](https://twitter.com/auxesis) on Twitter.
 * Check [issues on GitHub](https://github.com/auxesis/visage/issues).
