#
# Copyright 2015-2016, Noah Kantrowitz
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

require 'poise_ruby/resources/ruby_runtime_test'

# Poor man's build-essential.
package value_for_platform_family(
  debian: %w{autoconf binutils-doc bison build-essential flex gettext ncurses-dev},
  rhel: %w{autoconf bison flex gcc gcc-c++ kernel-devel make m4 patch},
)

# Install lsb-release because Debian 6 doesn't by default and serverspec requires it
package 'lsb-release' if platform?('debian') && node['platform_version'].start_with?('6')

ruby_runtime_test 'chef' do
  runtime_provider :chef
end

ruby_runtime_test 'system' do
  version ''
  runtime_provider :system
end

if platform_family?('rhel')
  ruby_runtime_test 'scl' do
    version ''
    runtime_provider :scl
  end
else
  file '/no_scl'
end

include_recipe '::bundle_install'
