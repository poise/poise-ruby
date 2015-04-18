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

require 'chef/config'
require 'chef/log'
require 'chef/mixin/shell_out'
require 'chef/mixin/which'
require 'chef/provider'
require 'chef/resource'
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
      class Resource < Chef::Resource
        include Poise(parent: true)
        include Chef::Mixin::Which
        provides(:ruby_execute)
        actions(:run)

        # @!attribute parent_ruby
        #   Parent ruby installation.
        #   @return [PoiseRuby::Resources::Ruby::Resource, nil]
        parent_attribute(:ruby, type: PoiseRuby::Resources::RubyRuntime::Resource, optional: true)
        # @!attribute command
        #   Command to run. This should not include the ruby itself, just the
        #   arguments to it.
        #   @return [String, Array<String>]
        attribute(:command, kind_of: [String, Array], name_attribute: true)
        # @!attribute directory
        #   Working directory for the command. Defaults to the home directory of
        #   the configured user or / if not found.
        #   @return [String]
        attribute(:directory, kind_of: String, default: lazy { default_directory })
        # @!attribute environment
        #   Environment variables for the command.
        #   @return [Hash]
        attribute(:environment, kind_of: Hash, default: {})
        # @!attribute user
        #   User to run the command as.
        #   @return [String]
        attribute(:user, kind_of: String, default: 'root')

        # For compatability with Chef's execute resource.
        alias_method :cwd, :directory

        # Nicer name for the hell of it.
        alias_method :ruby, :parent_ruby

        # The ruby binary to use for this command.
        #
        # @return [String]
        def ruby_binary
          if parent_ruby
            parent_ruby.ruby_binary
          else
            which('ruby')
          end
        end

        private

        # Try to find the home diretory for the configured user. This will fail if
        # nsswitch.conf was changed during this run such as with LDAP. Defaults to
        # the system root directory.
        #
        # @see #directory
        # @return [String]
        def default_directory
          # For root we always want the system root path.
          unless user == 'root'
            # Force a reload in case any users were created earlier in the run.
            Etc.endpwent
            home = begin
              Dir.home(user)
            rescue ArgumentError
              nil
            end
          end
          # Better than nothing
          home || case node['platform_family']
          when 'windows'
            ENV.fetch('SystemRoot', 'C:\\')
          else
            '/'
          end
        end
      end

      # The default provider for `ruby_execute`.
      #
      # @see Resource
      # @provides ruby_execute
      class Provider < Chef::Provider
        include Poise
        include Chef::Mixin::ShellOut
        provides(:ruby_execute)

        # The `run` action for `ruby_execute`. Run the command.
        #
        # @return [void]
        def action_run
          shell_out!(command, command_options)
          new_resource.updated_by_last_action(true)
        end

        private

        # Command to pass to shell_out.
        #
        # @return [String, Array<String>]
        def command
          if new_resource.command.is_a?(Array)
            [new_resource.ruby_binary] + new_resource.command
          else
            "#{new_resource.ruby_binary} #{new_resource.command}"
          end
        end

        # Options to pass to shell_out.
        #
        # @return [Hash<Symbol, Object>]
        def command_options
          {}.tap do |opts|
            opts[:cwd] = new_resource.directory
            opts[:environment] = new_resource.environment
            opts[:user] = new_resource.user
            opts[:log_level] = :info
            opts[:log_tag] = new_resource.to_s
            if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info? && !new_resource.sensitive
              opts[:live_stream] = STDOUT
            end
          end
        end
      end
    end
  end
end
