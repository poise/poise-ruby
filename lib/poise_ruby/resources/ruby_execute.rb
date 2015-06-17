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

require 'chef/mixin/which'
require 'chef/provider/execute'
require 'chef/resource/execute'
require 'poise'

require 'poise_ruby/resources/ruby_runtime'


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
        include Poise(parent: true)
        provides(:ruby_execute)
        actions(:run)

        # @!attribute parent_ruby
        #   Parent ruby installation.
        #   @return [PoiseRuby::Resources::Ruby::Resource, nil]
        parent_attribute(:ruby, type: :ruby_runtime, optional: true)

        # Nicer name for the DSL.
        alias_method :ruby, :parent_ruby
      end

      # The default provider for `ruby_execute`.
      #
      # @see Resource
      # @provides ruby_execute
      class Provider < Chef::Provider::Execute
        include Poise
        include Chef::Mixin::Which
        provides(:ruby_execute)

        private

        # The ruby binary to use for this command.
        #
        # @return [String]
        def ruby_binary
          if new_resource.parent_ruby
            new_resource.parent_ruby.ruby_binary
          else
            which('ruby')
          end
        end

        # Command to pass to shell_out.
        #
        # @return [String, Array<String>]
        def command
          if new_resource.command.is_a?(Array)
            [ruby_binary] + new_resource.command
          else
            "#{ruby_binary} #{new_resource.command}"
          end
        end

      end
    end
  end
end
