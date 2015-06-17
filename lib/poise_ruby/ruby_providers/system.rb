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

require 'chef/resource'

require 'poise_ruby/error'
require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    class System < Base
      provides(:system)

      PACKAGES = {
        debian: {
          '8' => %w{ruby2.1},
          '7' => %w{ruby1.9.3 ruby1.9.1 ruby1.8},
           # Debian 6 has a ruby1.9.1 package that installs 1.9.2, ignoring it for now.
          '6' => %w{ruby1.8},
        },
        ubuntu: {
          '14.04' => %w{ruby2.0 ruby1.9.3},
          '12.04' => %w{ruby1.9.3 ruby1.8},
          '10.04' => %w{ruby1.9.1 ruby1.8},
        },
        rhel: {default: %w{ruby}},
        centos: {default: %w{ruby}},
        fedora: {default: %w{ruby}},
        # Amazon Linux does actually have packages ruby18, ruby19, ruby20, ruby21.
        # Ignoring for now because wooooo non-standard formatting.
        amazon: {default: %w{ruby}},
      }

      def self.provides_auto?(node, resource)
        node.platform_family?('debian', 'rhel', 'amazon', 'fedora')
      end

      def self.default_inversion_options(node, resource)
        super.merge({
          # Install dev headers?
          dev_package: true,
          # Install a separate rubygems package? Only needed for 1.8.
          rubygems_package: node['platform_family'] == 'rhel' && node['platform_version'].start_with?('6'),
          # Manual overrides for package name and/or version.
          package_name: nil,
          package_version: nil,
          # Set to true to use action :upgrade on all packages.
          package_upgrade: false,
        })
      end

      def action_install
        install_ruby
      end

      def action_uninstall
        remove_ruby
      end

      # Output value for the Ruby binary we are installing. Seems to match
      # package name on all platforms I've checked.
      def ruby_binary
        ::File.join('', 'usr', 'bin', package_name)
      end

      private

      def install_ruby
        action = options['package_upgrade'] ? :upgrade : :install
        run_package_action(package_name, options['version'], action)
      end

      def remove_ruby
        action = node.platform_family?('debian') ? :purge : :remove
        run_package_action(package_name, options['version'], action, check_version: false)
      end

      # Compute the package name for the development headers.
      #
      # @param package_name [String] Package name for the Ruby.
      # @return [String]
      def dev_package_name(package_name)
        return options['dev_package'] if options['dev_package'].is_a?(String)
        suffix = node.value_for_platform_family(debian: '-dev', rhel: '-devel', fedora: '-devel')
        # Platforms like Arch and Gentoo don't need this anyway. I've got no
        # clue how Amazon Linux does this.
        return unless suffix
        dev_package_name = package_name + suffix
        if dev_package_name == 'ruby1.9.3-dev'
          # WTF Ubuntu, seriously.
          dev_package_name = 'ruby1.9.1-dev'
        end
        dev_package_name
      end

      def package_resource(package_name)
        names = [package_name]
        if options['dev_package'] && d = dev_package_name(package_name)
          names << d
        end
        if options['rubygems_package']
          names << (options['rubygems_package'].is_a?(String) ? options['rubygems_package'] : 'rubygems')
        end

        Chef::Log.debug("[#{new_resource}] Building package resource using #{names.inspect}.")
        @package_resource ||= Chef::Resource::Package.new(names, run_context).tap do |r|
          r.version([options['package_version'], options['package_version'], nil])
        end
      end

      def run_package_action(package_name, ruby_version, action, check_version: true)
        resource = package_resource(package_name)
        # Reset it so we have a clean baseline.
        resource.updated_by_last_action(false)
        # Grab the provider.
        provider = resource.provider_for_action(action)
        # Check the candidate version if needed
        patch_load_current_resource!(provider, ruby_version) if check_version
        # Run our action.
        provider.run_action(action)
        # Check updated flag.
        new_resource.updated_by_last_action(true) if resource.updated_by_last_action?
      end

      # Hack a provider object to run our verification code.
      #
      # @param provider [Chef::Provider] Provider object to patch.
      # @param ruby_version [String] Ruby version to check for.
      # @return [void]
      def patch_load_current_resource!(provider, ruby_version)
        # Create a closure module and inject it.
        provider.extend Module.new do
          # Patch load_current_resource to run our verification logic after
          # the normal code.
          define_method(:load_current_resource) do
            super().tap do |val|
              unless candidate_version_array.first && candidate_version_array.first.start_with?(ruby_version)
                raise PoiseRuby::Error.new("Package #{package_name_array.first} would install #{candidate_version_array.first}, which does not match #{ruby_version}. Please set the package_name or package_version provider options.")
              end
            end
          end
        end
      end

      def package_name
        # If manually set, use that.
        return options['package_name'] if options['package_name']
        # Find package names known to exist.
        known_packages = node.value_for_platform(PACKAGES)
        unless known_packages
          Chef::Log.debug("[#{new_resource}] No known packages for #{node['platform']} #{node['platform_version']}, defaulting to 'ruby'.")
          known_packages = %w{ruby}
        end
        # version nil -> ''.
        version = options['version'] || ''
        # Find the first value on candidate_names that is in known_packages.
        candiate_names(version).each do |name|
          return name if known_packages.include?(name)
        end
        # No valid candidate. Sad trombone.
        raise PoiseRuby::Error.new("Unable to find a candidate package for Ruby version #{version.inspect}. Please set package_name provider options.")
      end

      def candiate_names(version)
        [].tap do |names|
          # Might as well try it.
          names << "ruby#{version}" if version && !['', '1', '2'].include?(version)
          # On debian, 1.9.1 and 1.9.3 have special packages.
          if match = version.match(/^(\d+\.\d+\.\d+)/)
            names << "ruby#{match[1]}"
          end
          # Normal debian package like ruby2.0.
          if match = version.match(/^(\d+\.\d+)/)
            names << "ruby#{match[1]}"
          end
          # Aliases for ruby1 and ruby2
          if version == '2' || version == ''
            # 2.3 is on there for future proofing. Well, at least giving me a
            # buffer zone.
            names.concat(%w{ruby2.3 ruby2.2 ruby2.1 ruby2.0})
          end
          if version == '1' || version == ''
            names.concat(%w{ruby1.9.3 ruby1.9 ruby1.8})
          end
          # For RHEL and friends.
          names << 'ruby'
          names.uniq!
        end
      end

    end
  end
end
