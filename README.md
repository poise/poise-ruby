poise-ruby
==========

[![Build Status](https://travis-ci.org/poise/poise-ruby.png?branch=master)](https://travis-ci.org/poise/poise-ruby)

Install omnibus'd Ruby builds via [ruby.poise.io](http://ruby.poise.io).

Supports:
* Ubuntu 10.04, 12.04, and 13.10,
* Debian 6 and 7.

CentOS 5 and 6 support is coming soon, and possibly Fedora 19.

Quick Start
-----------

Add `recipe[poise-ruby]` to your application role, and add `/opt/ruby-210/bin`
to your `$PATH` for commands and init scripts.

```ruby
gem_package 'bundler' do
  gem_binary '/opt/ruby-210/bin/gem'
end

execute '/opt/ruby-210/bin/bundle install' do
  cwd '/srv/myapp'
  environment 'PATH' => "/opt/ruby-210/bin:#{ENV['PATH']}"
end
```

Attributes
----------

* `node['poise-ruby']['ruby']` – Flavor of Ruby to install by default. See list of recipes below for details. *(default: ruby-210)*
* `node['poise-ruby']['version']` – Version of the Ruby package to install. By default, the latest is installed.

Recipes
-------

* `poise-ruby` – Installs the flavor of Ruby defined by `node['poise-ruby']['ruby']`
* `poise-ruby::ruby-210` – Installs Ruby 2.1.0
* `poise-ruby::ruby-200` – Installs Ruby 2.0.0
* `poise-ruby::ruby-200-gems-21` – Installs Ruby 2.0.0 with Rubygems 2.1
* `poise-ruby::ruby-200-gems-20` – Installs Ruby 2.0.0 with Rubygems 2.0
* `poise-ruby::ruby-193` – Installs Ruby 1.9.3
* `poise-ruby::ruby-193-gems-20` – Installs Ruby 1.9.3 with Rubygems 2.0
* `poise-ruby::ruby-193-gems-18` – Installs Ruby 1.9.3 with Rubygems 1.8

Resources
---------

### poise_ruby

Configure the package repository and install a given flavor and version of Ruby.

```ruby
poise_ruby 'ruby-200' do
  version '2.0.0-p353'
end
```

* `package_name` – Name of the flavor of Ruby to install. *(name_attribute)*
* `version` – Version of the package to install.

Manual Use
----------

So maybe Chef isn't your cup of tea? No problem.

For Debian-related distributions:

```bash
$ sudo apt-add-repository http://ruby.poise.io
$ sudo apt-key adv --keyserver hkp://pgp.mit.edu --recv 594F6D7656399B5C
$ sudo apt-get update
$ sudo apt-get install ruby-210
```

