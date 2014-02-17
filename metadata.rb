#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name 'poise-ruby'
version '1.0.0'

maintainer 'Noah Kantrowitz'
maintainer_email 'noah@coderanger.net'
license 'Apache 2.0'
description 'Installs a Ruby packages from ruby.poise.io'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

depends 'apt'
depends 'poise'
depends 'yum'

recipe 'poise-ruby', "Installs the flavor of Ruby defined by node['poise-ruby']['ruby']."
recipe 'poise-ruby::ruby-210', 'Installs Ruby 2.1.0.'
recipe 'poise-ruby::ruby-200', 'Installs Ruby 2.0.0.'
recipe 'poise-ruby::ruby-200-gems-21', 'Installs Ruby 2.0.0 with Rubygems 2.1.'
recipe 'poise-ruby::ruby-200-gems-20', 'Installs Ruby 2.0.0 with Rubygems 2.0.'
recipe 'poise-ruby::ruby-193', 'Installs Ruby 1.9.3.'
recipe 'poise-ruby::ruby-193-gems-20', 'Installs Ruby 1.9.3 with Rubygems 2.0.'
recipe 'poise-ruby::ruby-193-gems-18', 'Installs Ruby 1.9.3 with Rubygems 1.8.'

attribute 'poise-ruby/ruby',
          :description => 'Flavor of Ruby to install by default (default: ruby-210).',
          :default => 'ruby-210'

attribute 'poise-ruby/version',
          :description => 'Version of the Ruby package to install. By default, the latest is installed.'
