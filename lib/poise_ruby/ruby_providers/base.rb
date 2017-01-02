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

require 'chef/provider'
require 'poise'

require 'poise_ruby/resources/ruby_gem'
require 'poise_ruby/resources/ruby_runtime'


module PoiseRuby
  module RubyProviders
    class Base < Chef::Provider
      include Poise(inversion: :ruby_runtime)

      # Set default inversion options.
      #
      # @api private
      def self.default_inversion_options(node, new_resource)
        super.merge({
          bundler_version: new_resource.bundler_version,
          version: new_resource.version,
        })
      end

      # The `install` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_install
        notifying_block do
          install_ruby
          install_bundler
        end
      end

      # The `uninstall` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_uninstall
        notifying_block do
          uninstall_ruby
        end
      end

      # The path to the `ruby` binary.
      #
      # @abstract
      # @return [String]
      def ruby_binary
        raise NotImplementedError
      end

      # Output property for environment variables.
      #
      # @return [Hash<String, String>]
      def ruby_environment
        # No environment variables needed. Rejoice.
        {}
      end

      # The path to the `gem` binary. Look relative to the
      # `ruby` binary for a default implementation.
      #
      # @return [String]
      def gem_binary
        dir, base = ::File.split(ruby_binary)
        # If this ruby is called something weird, bail out.
        raise NotImplementedError unless base.start_with?('ruby')
        # Allow for names like "ruby2.0" -> "gem2.0".
        ::File.join(dir, base.sub(/^ruby/, 'gem'))
      end

      private

      # Install the Ruby runtime. Must be implemented by subclass.
      #
      # @abstract
      # @return [void]
      def install_ruby
      end

      # Uninstall the Ruby runtime. Must be implemented by subclass.
      #
      # @abstract
      # @return [void]
      def uninstall_ruby
      end

      # Install Bundler in to the Ruby runtime.
      #
      # @return [void]
      def install_bundler
        # Captured because #options conflicts with Chef::Resource::Package#options.
        bundler_version = options[:bundler_version]
        return unless bundler_version
        ruby_gem 'bundler' do
          action :upgrade if bundler_version == true
          parent_ruby new_resource
          version bundler_version if bundler_version.is_a?(String)
        end
      end
    end
  end
end
