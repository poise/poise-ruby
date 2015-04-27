#
# Copyright 2015, Noah Kantrowitz
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

# Install lsb-release because Debian 6 doesn't by default and serverspec requires it
package 'lsb-release' if platform?('debian') && node['platform_version'].start_with?('6')

ruby_runtime 'chef' do
  provider :chef
end

ruby_runtime 'any' do
  version ''
end

file '/root/poise_ruby_test.rb' do
  user 'root'
  group 'root'
  mode '644'
  content <<-EOH
File.open(ARGV[0], 'w') do |f|
  f.write(RUBY_VERSION)
end
EOH
end

ruby_execute '/root/poise_ruby_test.rb /root/one'

ruby_execute '/root/poise_ruby_test.rb /root/two' do
  ruby 'chef'
end

ruby_gem 'rack' do
  version '1.6.0'
end

file '/root/poise_ruby_test2.rb' do
  user 'root'
  group 'root'
  mode '644'
  content <<-EOH
require 'rubygems'
require 'rack'
File.open(ARGV[0], 'w') do |f|
  f.write(Rack.release)
end
EOH
end

ruby_execute '/root/poise_ruby_test2.rb /root/three'
