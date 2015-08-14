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

require 'chef/provider/execute'
require 'chef/resource/execute'
require 'poise'

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
      end

      # The default provider for `ruby_execute`.
      #
      # @see Resource
      # @provides ruby_execute
      class Provider < Chef::Provider::Execute
        provides(:ruby_execute)

        private

        # Command to pass to shell_out.
        #
        # @return [String, Array<String>]
        def command
          if new_resource.command.is_a?(Array)
            [new_resource.ruby] + new_resource.command
          else
            "#{new_resource.ruby} #{new_resource.command}"
          end
        end

        # Environment variables to pass to shell_out.
        #
        # @return [Hash]
        def environment
          if new_resource.parent_ruby
            environment = new_resource.parent_ruby.ruby_environment
            if new_resource.environment
              environment = environment.merge(new_resource.environment)
            end
            environment
          else
            new_resource.environment
          end
        end

      end
    end
  end
end
