# Poise-Ruby Cookbook

[![Build Status](https://img.shields.io/travis/poise/poise-ruby.svg)](https://travis-ci.org/poise/poise-ruby)
[![Gem Version](https://img.shields.io/gem/v/poise-ruby.svg)](https://rubygems.org/gems/poise-ruby)
[![Cookbook Version](https://img.shields.io/cookbook/v/poise-ruby.svg)](https://supermarket.chef.io/cookbooks/poise-ruby)
[![Coverage](https://img.shields.io/codecov/c/github/poise/poise-ruby.svg)](https://codecov.io/github/poise/poise-ruby)
[![Gemnasium](https://img.shields.io/gemnasium/poise/poise-ruby.svg)](https://gemnasium.com/poise/poise-ruby)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Chef](https://www.chef.io/) cookbook to provide a unified interface for
installing Ruby and running things with it. This README covers the 2.x version
of the cookbook, the 1.x version is very different and no longer supported.

## Quick Start

To install the latest available version of Ruby 2.x and then use it to install
some gems:

```ruby
ruby_runtime '2'

ruby_gem 'rake'

bundle_install '/path/to/Gemfile' do
  without 'development'
  deployment true
end
```

## Requirements

Chef 12.1 or newer is required.

## Attributes

Attributes are used to configure the default recipe.

* `node['poise-ruby']['install_ruby']` – Install a Ruby runtime. *(default: true)*
* `node['poise-ruby']['install_chef_ruby']` – Create a `ruby_runtime` using
  the `:chef` provider. Doesn't actually install anything. *(default: true)*

## Recipes

### `default`

The default recipe installs Ruby based on the node attributes. It is entirely
optional and can be ignored in favor of direct use of the `ruby_runtime`
resource.

## Resources

### `ruby_runtime`

The `ruby_runtime` resource installs a Ruby interpreter.

```ruby
ruby_runtime 'any' do
  version ''
end
```

#### Actions

* `:install` – Install the Ruby interpreter. *(default)*
* `:uninstall` – Uninstall the Ruby interpreter.

#### Properties

* `version` – Version of Ruby to install. If a partial version is given, use the
  latest available version matching that prefix. *(name properties)*

#### Provider Options

The `poise-ruby` library offers an additional way to pass configuration
information to the final provider called "options". Options are key/value pairs
that are passed down to the ruby_runtime provider and can be used to control how it
installs Ruby. These can be set in the `ruby_runtime`
resource using the `options` method, in node attributes or via the
`ruby_runtime_options` resource. The options from all sources are merged
together in to a single hash.

When setting options in the resource you can either set them for all providers:

```ruby
ruby_runtime 'myapp' do
  version '2.1'
  options dev_package: false
end
```

or for a single provider:

```ruby
ruby_runtime 'myapp' do
  version '2.1'
  options :system, dev_package: false
end
```

Setting via node attributes is generally how an end-user or application cookbook
will set options to customize installations in the library cookbooks they are using.
You can set options for all installations or for a single runtime:

```ruby
# Global, for all installations.
override['poise-ruby']['options']['dev_package'] = false
# Single installation.
override['poise-ruby']['myapp']['version'] = '2.2'
```

The `ruby_runtime_options` resource is also available to set node attributes
for a specific installation in a DSL-friendly way:

```ruby
ruby_runtime_options 'myapp' do
  version '2.2'
end
```

Unlike resource attributes, provider options can be different for each provider.
Not all providers support the same options so make sure to the check the
documentation for each provider to see what options the use.

### `ruby_runtime_options`

The `ruby_runtime_options` resource allows setting provider options in a
DSL-friendly way. See [the Provider Options](#provider-options) section for more
information about provider options overall.

```ruby
ruby_runtime_options 'myapp' do
  version '2.2'
end
```

#### Actions

* `:run` – Apply the provider options. *(default)*

#### Properties

* `resource` – Name of the `ruby_runtime` resource. *(name property)*
* `for_provider` – Provider to set options for.

All other property keys will be used as options data.

### `ruby_execute`

The `ruby_execute` resource executes a Ruby script using the configured runtime.

```ruby
ruby_execute 'myapp.rb' do
  user 'myuser'
end
```

This uses the built-in `execute` resource and supports all the same properties.

#### Actions

* `:run` – Execute the script. *(default)*

#### Properties

* `command` – Script and arguments to run. Must not include the `ruby`. *(name property)*
* `ruby` – Name of the `ruby_runtime` resource to use. If not specified, the
  most recently declared `ruby_runtime` will be used.

For other properties see the [Chef documentation](https://docs.chef.io/resource_execute.html#attributes).

### `ruby_gem`

The `ruby_gem` resource is a subclass of the standard `gem_package` resource to
install the gem with the configured runtime.

```ruby
ruby_gem 'rake' do
  version ' 10.4.2'
end
```

All actions and attributes match the standard `gem_package` resource with the
addition of a `ruby` attribute matching `ruby_execute`.

### `bundle_install`

The `bundle_install` resource installs gems based on a Gemfile using
[bundler](http://bundler.io/).

```ruby
bundle_install '/path/to/Gemfile' do
  deployment true
  jobs 3
end
```

The underlying `bundle` command will run on every converge, but notifications
will only be triggered if a gem is actually installed.

#### Actions

* `:install` – Run `bundle install`. *(default)*
* `:update` – Run `bundle update`.

#### Properties

* `path` – Path to a Gemfile or a directory containing a Gemfile. *(name property)*
* `binstubs` – Enable binstubs. If set to a string it is the path to generate
  stubs in.
* `bundler_version` – Version of bundler to install. If unset the latest version is used.
* `deployment` – Enable deployment mode.
* `gem_binary` – Path to the gem binary. If unset this uses the `ruby_runtime` parent.
* `jobs` – Number of parallel installations to run.
* `retry` – Number of times to retry failed installations.
* `ruby` – Name of the `ruby_runtime` resource to execute against.
* `user` – User to run bundler as.
* `vendor` – Enable local vendoring. This maps to the `--path` option in bundler,
  but that attribute name is already used.
* `without` – Group or groups to not install.

## Ruby Providers

### `system`

The `system` provider installs Ruby using system packages. This is currently
only tested on platforms using `apt-get` and `yum` (Debian, Ubuntu, RHEL, CentOS
Amazon Linux, and Fedora) and is the default provider on those platforms. It
may work on other platforms but is untested.

```ruby
ruby_runtime 'myapp' do
  provider :system
  version '2.1'
end
```

#### Options

* `dev_package` – Install the package with the headers and other development
  files. *(default: true)*
* `rubygems_package` – Install rubygems from a package. This is only needed for
  Ruby 1.8. *(default: true on RHEL 6)*
* `package_name` – Override auto-detection of the package name.
* `package_upgrade` – Install using action `:upgrade`. *(default: false)*
* `package_version` – Override auto-detection of the package version.
* `version` – Override the Ruby version.

### `scl`

The `scl` provider installs Ruby using the [Software Collections](https://www.softwarecollections.org/)
packages. This is only available on RHEL and CentOS. SCL offers more
recent versions of Ruby than the system packages for the most part. If an SCL
package exists for the requested version, it will be used in preference to the
`system` provider.

```ruby
ruby_runtime 'myapp' do
  provider :scl
  version '2.2'
end
```

### `chef`

The `chef` provider uses the Ruby environment included in the Omnibus packages.
Great care should be taken when using this provider.

```ruby
ruby_runtime 'myapp' do
  provider :chef
  version '2.1'
end
```

#### Options

* `version` – Override the Ruby version.

### `ruby_build`

The `ruby_build` provider uses [ruby-build](https://github.com/sstephenson/ruby-build)
to compile and install Ruby. It can be found in the
[poise-ruby-build cookbook](https://github.com/poise/poise-ruby-build).

## Sponsors

Development sponsored by [Bloomberg](http://www.bloomberg.com/company/technology/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015-2017, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
