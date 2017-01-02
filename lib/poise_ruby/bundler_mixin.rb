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

require 'poise_ruby/error'


module PoiseRuby
  # Mixin for creating bundle exec commands.
  #
  # @since 2.1.0
  module BundlerMixin
    # Transform a command to run under `bundle exec` with the same semantics as
    # Ruby execution elsewhere in this system. That means you should end up with
    # something like `/bin/ruby /bin/bundle exec /bin/ruby /bin/cmd args`.
    #
    # @param cmd [String, Array<String>] Command to transform.
    # @param path [String] Optional input path for command resolution.
    # @return [String, Array<String>]
    def bundle_exec_command(cmd, path: nil)
      bundle = new_resource.parent_bundle
      return cmd unless bundle
      is_array = cmd.is_a?(Array)
      cmd = Shellwords.split(cmd) unless is_array
      root_path = ::File.expand_path('..', bundle.gemfile_path)
      # Grab this once in case I need it for the extra path.
      bundler_binary = bundle.bundler_binary
      # This doesn't account for the potential of a .bundle/config created with
      # settings that Chef doesn't know about. (╯°□°）╯︵ ┻━┻
      extra_path = if bundle.binstubs
        bundle.binstubs == true ? 'bin' : bundle.binstubs
      elsif bundle.vendor || bundle.deployment
        # Find the relative path to start searching from.
        vendor_base_path = if bundle.vendor && bundle.vendor != true
          bundle.vendor
        else
          'vendor/bundle'
        end
        # Add the ruby/.
        vendor_base_path = ::File.join(File.expand_path(vendor_base_path, root_path), 'ruby')
        # Find the version number folder inside that.
        candidates = Dir.entries(vendor_base_path)
        ruby_abi_folder = candidates.find {|name| name =~ /^\d\./ }
        vendor_sub_path = if ruby_abi_folder
          ::File.join(ruby_abi_folder, 'bin')
        elsif candidates.include?('bin')
          'bin'
        else
          raise PoiseRuby::Error.new("Unable to find the vendor bin folder for #{vendor_base_path}: #{candidates.join(', ')}")
        end
        # Make the final path.
        ::File.join(vendor_base_path, vendor_sub_path)
      else
        # The folder the bundler binary is in was the global gem executable dir.
        ::File.dirname(bundler_binary)
      end
      # Resolve relative paths against Bundler.root.
      extra_path = ::File.expand_path(extra_path, root_path)
      # Create the full $PATH.
      path ||= ENV['PATH']
      bundle_exec_path = extra_path + ::File::PATH_SEPARATOR + path
      # Resolve the command
      abs_cmd = PoiseLanguages::Utils.absolute_command(cmd, path: bundle_exec_path)
      bundle_exec = [new_resource.ruby, bundler_binary, 'exec', new_resource.ruby] + abs_cmd
      if is_array
        bundle_exec
      else
        PoiseLanguages::Utils.shelljoin(bundle_exec)
      end
    end
  end
end
