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

require 'chef/resource'
require 'poise'


module PoiseRuby
  module Resources
    # (see RubyRuntime::Resource)
    # @since 2.0.0
    module RubyRuntime
      # A `ruby_runtime` resource to manage Ruby installations.
      #
      # @provides ruby_runtime
      # @action install
      # @action uninstall
      # @example
      #   ruby_runtime '2.1.2'
      class Resource < Chef::Resource
        include Poise(inversion: true, container: true)
        provides(:ruby_runtime)
        actions(:install, :uninstall)

        # @!attribute version
        #   Version of Ruby to install.
        #   @return [String]
        attribute(:version, kind_of: String, name_attribute: true)
        # @!attribute bundler_version
        #   Version of Bundler to install. It set to `true`, the latest
        #   available version will be used. If set to `false`, Bundler will
        #   not be installed.
        #   @note Disabling the Bundler install may result in other resources
        #     being non-functional.
        #   @return [String, Boolean]
        attribute(:bundler_version, kind_of: [String, TrueClass, FalseClass], default: true)

        # The path to the `ruby` binary for this Ruby installation. This is an
        # output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('ruby_runtime[2.2.2]').ruby_binary} myapp.rb"
        def ruby_binary
          @ruby_binary ||= provider_for_action(:ruby_binary).ruby_binary
        end

        # The environment variables for this Ruby installation. This is an
        # output property.
        #
        # @return [Hash<String, String>]
        # @example
        #   execute '/opt/myapp.py' do
        #     environment resources('ruby_runtime[2.2.2]').ruby_environment
        #   end
        def ruby_environment
          @ruby_environment ||= provider_for_action(:ruby_environment).ruby_environment
        end

        # The path to the `gem` binary for this Ruby installation. This is an
        # output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('ruby_runtime[2.2.2]').gem_binary} install myapp"
        def gem_binary
          @gem_binary ||= provider_for_action(:gem_binary).gem_binary
        end
      end

      # Providers can be found under lib/poise_ruby/ruby_providers/
    end
  end
end
