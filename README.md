visage
======

Visage is a web interface for viewing `collectd` statistics.

It also provides a JSON interface onto `collectd`'s RRD data. giving you an easy
way to mash up the data.

Installing
----------

Freeze in dependencies:

    $ rake deps

Developing
----------

For development: 

    $ gem install shotgun
    $ shotgun sinatra-collectd.rb

Deploying
---------

With Passenger, create an Apache vhost with the `DocumentRoot` set to the 
`public/` directory of where you have deployed the checked out code, e.g.

    <VirtualHost *>
      ServerName visage.example.org
      ServerAdmin contact@visage.example.org
    
      DocumentRoot /srv/www/visage.example.org/root/public/
    
      <Directory "/srv/www/visage.example.org/root/public/">
         Options FollowSymLinks Indexes
         AllowOverride None
         Order allow,deny
         Allow from all 
       </Directory>
    
       ErrorLog /srv/www/visage.example.org/log/apache_errors_log
       CustomLog /srv/www/visage.example.org/log/apache_app_log combined
    
    </VirtualHost>

This assumes you have a checkout of the code at `/srv/www/visage.example.org/root`.

If you don't want to use Apache + Passenger, you can install the `thin` or 
`mongrel` gems and run up a web server yourself. 


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
 * handle single plugin instance in graphing code - DONE
 * specify data url in graphing code - DONE
 * generate holders for graph/labels/time selector - DONE
 * axis labels (with human readable times)
 * zoom + dynamic resize - DONE
 * combine graphs from different hosts
 * comment on time periods
 * view list of comments
