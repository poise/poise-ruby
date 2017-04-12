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

require 'chef/mixin/shell_out'
require 'chef/mixin/which'
require 'chef/provider'
require 'chef/resource'
require 'poise'

require 'poise_ruby/error'
require 'poise_ruby/ruby_command_mixin'


module PoiseRuby
  module Resources
    # (see BundleInstall::Resource)
    # @since 2.0.0
    module BundleInstall
      # A `bundle_install` resource to install a [Bundler](http://bundler.io/)
      # Gemfile.
      #
      # @provides bundle_install
      # @action install
      # @action update
      # @note
      #   This resource is not idempotent itself, it will always run `bundle
      #   install`.
      # @example
      #   bundle_install '/opt/my_app' do
      #     gem_path '/usr/local/bin/gem'
      #   end
      class Resource < Chef::Resource
        include Poise
        provides(:bundle_install)
        actions(:install, :update)
        include PoiseRuby::RubyCommandMixin

        # @!attribute path
        #   Path to the Gemfile or to a directory that contains a Gemfile.
        #   @return [String]
        attribute(:path, kind_of: String, name_attribute: true)
        # @!attribute binstubs
        #   Enable binstubs. If set to a string it is the path to generate
        #   stubs in.
        #   @return [Boolean, String]
        attribute(:binstubs, kind_of: [TrueClass, String])
        # @!attribute deployment
        #   Enable deployment mode.
        #   @return [Boolean]
        attribute(:deployment, equal_to: [true, false], default: false)
        # @!attribute jobs
        #   Number of parallel installations to run.
        #   @return [String, Integer]
        attribute(:jobs, kind_of: [String, Integer])
        # @!attribute retry
        #   Number of times to retry failed installations.
        #   @return [String, Integer]
        attribute(:retry, kind_of: [String, Integer])
        # @!attribute user
        #   User to run bundler as.
        #   @return [String, Integery, nil]
        attribute(:user, kind_of: [String, Integer, NilClass])
        # @!attribute vendor
        #   Enable local vendoring. This maps to the `--path` option in bundler,
        #   but that attribute name is already used.
        #   @return [Boolean, String]
        attribute(:vendor, kind_of: [TrueClass, String])
        # @!attribute without
        #   Group or groups to not install.
        #   @return [String, Array<String>]
        attribute(:without, kind_of: [Array, String])

        # The path to the `bundle` binary for this installation. This is an
        # output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('bundle_install[/opt/myapp]').bundler_binary} vendor"
        def bundler_binary
          @bundler_binary ||= provider_for_action(:bundler_binary).bundler_binary
        end

        # The path to the Gemfile for this installation. This is an output
        # property.
        #
        # @return [String]
        # @example
        #   file resources('bundle_install[/opt/myapp]').gemfile_path do
        #     owner 'root'
        #   end
        def gemfile_path
          @gemfile_path ||= provider_for_action(:gemfile_path).gemfile_path
        end
      end

      # The default provider for the `bundle_install` resource.
      #
      # @see Resource
      class Provider < Chef::Provider
        include Poise
        provides(:bundle_install)
        include PoiseRuby::RubyCommandMixin

        # Install bundler and the gems in the Gemfile.
        def action_install
          run_bundler('install')
        end

        # Install bundler and update the gems in the Gemfile.
        def action_update
          run_bundler('update')
        end

        # Return the absolute path to the correct bundle binary to run.
        #
        # @return [String]
        def bundler_binary
          @bundler_binary ||= ::File.join(poise_gem_bindir, 'bundle')
        end

        # Find the absolute path to the Gemfile. This mirrors bundler's internal
        # search logic by scanning up to parent folder as needed.
        #
        # @return [String]
        def gemfile_path
          @gemfile_path ||= begin
            path = ::File.expand_path(new_resource.path)
            if ::File.file?(path)
              # We got a path to a real file, use that.
              path
            else
              # Walk back until path==dirname(path) meaning we are at the root
              while path != (next_path = ::File.dirname(path))
                possible_path = ::File.join(path, 'Gemfile')
                return possible_path if ::File.file?(possible_path)
                path = next_path
              end
            end
          end
        end

        private

        # Install the gems in the Gemfile.
        def run_bundler(command)
          return converge_by "Run bundle #{command}" if whyrun_mode?
          cmd = ruby_shell_out!(bundler_command(command), environment: {'BUNDLE_GEMFILE' => gemfile_path}, user: new_resource.user)
          # Look for a line like 'Installing $gemname $version' to know if we did anything.
          if cmd.stdout.include?('Installing')
            new_resource.updated_by_last_action(true)
          end
        end

        # Parse out the value for Gem.bindir. This is so complicated to minimize
        # the required configuration on the resource combined with gem having
        # terrible output formats.
        #
        # Renamed from #gem_bindir in 2.3.0 because of a conflict with a method
        # of the same name in Chef::Mixin::PathSanity (which is pulled in via
        # ShellOut) added in 13.0.
        #
        # @return [String]
        def poise_gem_bindir
          cmd = ruby_shell_out!(new_resource.gem_binary, 'environment')
          # Parse a line like:
          # - EXECUTABLE DIRECTORY: /usr/local/bin
          matches = cmd.stdout.scan(/EXECUTABLE DIRECTORY: (.*)$/).first
          if matches
            matches.first
          else
            raise PoiseRuby::Error.new("Cannot find EXECUTABLE DIRECTORY: #{cmd.stdout}")
          end
        end

        # Command line options for the bundle install.
        #
        # @return [Array<String>]
        def bundler_options
          [].tap do |opts|
            if new_resource.binstubs
              opts << "--binstubs" + (new_resource.binstubs.is_a?(String) ? "=#{new_resource.binstubs}" : '')
            end
            if new_resource.vendor
              opts << "--path=" + (new_resource.vendor.is_a?(String) ? new_resource.vendor : 'vendor/bundle')
            end
            if new_resource.deployment
              opts << '--deployment'
            end
            if new_resource.jobs
              opts << "--jobs=#{new_resource.jobs}"
            end
            if new_resource.retry
              opts << "--retry=#{new_resource.retry}"
            end
            if new_resource.without
              opts << '--without'
              opts.insert(-1, *new_resource.without)
            end
          end
        end

        # Command array to run when installing the Gemfile.
        #
        # @return [Array<String>]
        def bundler_command(command)
          [bundler_binary, command] + bundler_options
        end

      end
    end
  end
end
