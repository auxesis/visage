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

    $ visage-app start

Then paste the URL from the output into your browser.

If you get a `command not found` when running the above command (RubyGems likely
isn't on your PATH), try this instead:

    $ $(dirname $(dirname $(gem which visage-app)))/bin/visage-app start

Deploying
---------

Visage can be deployed on Apache with Passenger:

    $ sudo apt-get install libapache2-mod-passenger

Visage can attempt to generate an Apache vhost config for use with Passenger:

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

Copypasta this into your system's Apache config structure and tune to taste.

To do this on Debian/Ubuntu:

    $ sudo -s
    $ visage-app genapache > /etc/apache2/sites-enabled/visage
    $ a2dissite default
    $ service apache2 reload

Then head to your Apache instance and Visage will be up and running.

If you are not able to run Apache with Passenger, you can configure Visage
using a proxy configuration. This example also installs Visage to a sub path of
an existing website.

    $ visage-app genapache-proxy
    ProxyRequests Off
    <Proxy *>
      Order deny,allow
      Allow from all
    </Proxy>

    ProxyPass /visage http://localhost:9292
    ProxyPassReverse /visage http://localhost:9292

You can then use Upstart or another init script to keep Visage running

    $ visage-app genupstart
    description "Visage"
    author "John Ferlito <johnf@inodes.org>"

    env VISAGE_APP_BASE_URL_PATH=/visage
    export VISAGE_APP_BASE_URL_PATH

    respawn
    respawn limit 5 120

    exec visage-app start >>/var/log/visage.log 2>&1


To do this on Debian/Ubuntu:

    $ sudo -s
    $ visage-app genapache-proxy > /etc/apache2/conf.d/visage.conf
    $ a2enmod proxy
    $ a2enmod proxy_http
    $ service apache2 restart
    $ visage-app genupstart > /etc/init/visage.conf
    $ initctl reload-configuration
    $ service visage start

Configuring
-----------

Visage looks for two environment variables when starting up:

  * `CONFIG_PATH`, an entry on the configuration file search path
  * `RRDDIR`, the location of collectd's RRDs

Visage has a configuration search path which can be used for overriding
individual files. By default it has one entry: `$VISAGE_ROOT/lib/visage/config/`.
You can set the `CONFIG_PATH` environment variable to add another directory to
the config load path. This directory will be searched when loading up
configuration files.

    CONFIG_PATH=/var/lib/visage-app start

This is especially useful when you want to deploy + run Visage from an installed
gem with Passenger. e.g.

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

Also to keep in mind when deploying with Passenger, the `CONFIG_PATH` directory
and its files need to have the correct ownership:

    chown nobody:nogroup -R /var/lib/visage

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

