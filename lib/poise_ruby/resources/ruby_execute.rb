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

require 'chef/mash'
require 'chef/provider/execute'
require 'chef/resource/execute'
require 'poise'

require 'poise_ruby/bundler_mixin'
require 'poise_ruby/ruby_command_mixin'


module PoiseRuby
  module Resources
    # (see RubyExecute::Resource)
    # @since 2.0.0
    module RubyExecute
      # A `ruby_execute` resource to run Ruby scripts and commands.
      #
      # @provides ruby_execute
      # @action run
      # @example
      #   ruby_execute 'myapp.rb' do
      #     user 'myuser'
      #   end
      class Resource < Chef::Resource::Execute
        include Poise
        provides(:ruby_execute)
        actions(:run)
        include PoiseRuby::RubyCommandMixin

        # @!attribute parent_bundle
        #   Optional bundle_install resource to run `bundle exec` against.
        #   @return [PoiseRuby::Resources::BundleInstall::Resource]
        parent_attribute(:bundle, type: :bundle_install, optional: true, auto: false)
      end

      # The default provider for `ruby_execute`.
      #
      # @see Resource
      # @provides ruby_execute
      class Provider < Chef::Provider::Execute
        include PoiseRuby::BundlerMixin
        provides(:ruby_execute)

        private

        # Command to pass to shell_out.
        #
        # @return [String, Array<String>]
        def command
          if new_resource.parent_bundle
            bundle_exec_command(new_resource.command, path: environment['PATH'])
          else
            if new_resource.command.is_a?(Array)
              [new_resource.ruby] + new_resource.command
            else
              "#{new_resource.ruby} #{new_resource.command}"
            end
          end
        end

        # Environment variables to pass to shell_out.
        #
        # @return [Hash]
        def environment
          Mash.new.tap do |environment|
            environment.update(new_resource.parent_ruby.ruby_environment) if new_resource.parent_ruby
            environment['BUNDLE_GEMFILE'] = new_resource.parent_bundle.gemfile_path if new_resource.parent_bundle
            environment.update(new_resource.environment) if new_resource.environment
          end
        end

      end
    end
  end
end
