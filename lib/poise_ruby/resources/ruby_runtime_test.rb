#
# Copyright 2015-2017, Noah Kantrowitz
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

require 'chef/mixin/convert_to_class_name'
require 'chef/provider'
require 'chef/resource'
require 'poise'


module PoiseRuby
  module Resources
    # (see RubyRuntimeTest::Resource)
    # @since 2.1.0
    # @api private
    module RubyRuntimeTest
      # A `ruby_runtime_test` resource for integration testing of this
      # cookbook. This is an internal API and can change at any time.
      #
      # @provides ruby_runtime_test
      # @action run
      class Resource < Chef::Resource
        include Poise
        provides(:ruby_runtime_test)
        actions(:run)

        attribute(:version, kind_of: String, name_attribute: true)
        attribute(:runtime_provider, kind_of: Symbol)
        attribute(:path, kind_of: String, default: lazy { default_path })

        def default_path
          ::File.join('', 'root', "ruby_test_#{name}")
        end
      end

      # The default provider for `ruby_runtime_test`.
      #
      # @see Resource
      # @provides ruby_runtime_test
      class Provider < Chef::Provider
        include Poise
        provides(:ruby_runtime_test)

        # The `run` action for the `ruby_runtime_test` resource.
        #
        # @return [void]
        def action_run
          notifying_block do
            # Top level directory for this test.
            directory new_resource.path

            # Install and log the version.
            ruby_runtime new_resource.name do
              provider new_resource.runtime_provider if new_resource.runtime_provider
              version new_resource.version
            end
            test_version

            # Test ruby_gem.
            ruby_gem 'thor remove before' do
              action :remove
              package_name 'thor'
              ruby new_resource.name
            end
            test_require('thor', 'thor_before')
            ruby_gem 'thor' do
              ruby new_resource.name
              notifies :create, sentinel_file('thor'), :immediately
            end
            test_require('thor', 'thor_mid')
            ruby_gem 'thor again' do
              package_name 'thor'
              ruby new_resource.name
              notifies :create, sentinel_file('thor2'), :immediately
            end
            ruby_gem 'thor remove after' do
              action :remove
              package_name 'thor'
              ruby new_resource.name
            end
            test_require('thor', 'thor_after')

            # Use bundler to test something that should always be installed.
            ruby_gem 'bundler' do
              ruby new_resource.name
              notifies :create, sentinel_file('bundler'), :immediately
            end

            # Create and install a Gemfile.
            bundle1_path = ::File.join(new_resource.path, 'bundle1')
            directory bundle1_path
            file ::File.join(bundle1_path, 'Gemfile') do
              content <<-EOH
source 'https://rubygems.org/'
gem 'hashie'
gem 'tomlrb', '1.1.0'
EOH
            end
            bundle1 = bundle_install bundle1_path do
              ruby new_resource.name
            end
            test_require('hashie', bundle: bundle1)
            test_require('tomlrb', bundle: bundle1)
            test_require('thor', 'thor_bundle', bundle: bundle1)

            # Test for bundle exec shebang issues.
            bundle2_path = ::File.join(new_resource.path, 'bundle2')
            directory bundle2_path
            file ::File.join(bundle2_path, 'Gemfile') do
              content <<-EOH
source 'https://rubygems.org/'
gem 'unicorn'
EOH
            end
            file ::File.join(bundle2_path, 'Gemfile.lock') do
              content <<-EOH
GEM
  remote: https://rubygems.org/
  specs:
    kgio (2.10.0)
    rack (1.6.4)
    raindrops (0.15.0)
    unicorn (4.9.0)
      kgio (~> 2.6)
      rack
      raindrops (~> 0.7)

PLATFORMS
  ruby

DEPENDENCIES
  unicorn

BUNDLED WITH
   1.10.6
EOH
            end
            bundle2 = bundle_install bundle2_path do
              ruby new_resource.name
              deployment true
            end
            # test_require('unicorn', bundle: bundle2)
            ruby_execute "unicorn --version > #{::File.join(new_resource.path, "unicorn_version")}" do
              ruby new_resource.name
              parent_bundle bundle2
            end
          end
        end

        def sentinel_file(name)
          file ::File.join(new_resource.path, "sentinel_#{name}") do
            action :nothing
          end
        end

        private

        def test_version(ruby: new_resource.name)
          # Only queue up this resource once, the ivar is just for tracking.
          @ruby_version_test ||= file ::File.join(new_resource.path, 'ruby_version.rb') do
            user 'root'
            group 'root'
            mode '644'
            content <<-EOH
File.new(ARGV[0], 'w').write(RUBY_VERSION)
EOH
          end

          ruby_execute "#{@ruby_version_test.path} #{::File.join(new_resource.path, 'version')}" do
            ruby ruby if ruby
          end
        end

        def test_require(name, path=name, ruby: new_resource.name, bundle: nil, class_name: nil)
          # Only queue up this resource once, the ivar is just for tracking.
          @ruby_require_test ||= file ::File.join(new_resource.path, 'require_version.rb') do
            user 'root'
            group 'root'
            mode '644'
            content <<-EOH
require 'rubygems'
begin
  require "\#{ARGV[0]}/version"
  klass = ARGV[1].split('::').inject(Object) {|memo, name| memo.const_get(name) }
  File.new(ARGV[2], 'w').write(klass::VERSION)
rescue LoadError
end
EOH
          end

          class_name ||= Chef::Mixin::ConvertToClassName.convert_to_class_name(name)
          ruby_execute "#{@ruby_require_test.path} #{name} #{class_name} #{::File.join(new_resource.path, "require_#{path}")}" do
            ruby ruby if ruby
            parent_bundle bundle if bundle
          end
        end

      end
    end
  end
end
