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

      def self.provides_auto?(node, resource)
        true
      end

      def action_install
        notifying_block do
          install_package
        end
      end

      def action_uninstall
        notifying_block do
          remove_package
        end
      end

      def ruby_binary
      end

      private

      def install_package
        candidate = find_candidate
        mode = install_mode
        package candidate[:name] do
          action mode
          version candidate[:version]
        end
      end

      def remove_package
        install_package.tap do |r|
          # Try to purge if on debian-ish.
          r.action(node.platform_family?('debian') ? :purge : :remove)
        end
      end

      def find_candidate
        names = if options['package_name']
          [options['package_name']]
        else
          candiate_names(new_resource.version)
        end
        names.each do |name|
          version = candidate_version(name)
          ::Chef::Log.debug("[#{new_resource}] Found candidate version #{version.inspect} for package #{name}")
          # Trim epoch bullshit.
          if version && version.sub(/^\d:/, '').start_with?(new_resource.version)
            return {name: name, version: version}
          end
        end
        # No valid candidate. Sad trombone.
        raise PoiseRuby::Error.new("Unable to find a candidate package for Ruby version #{new_resource.version}")
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
          elsif version == '1' || version == ''
            names.concat(%w{ruby1.9.3 ruby1.9 ruby1.8})
          end
          # For RHEL and friends.
          names << "ruby"
          names.uniq!
        end
      end

      def candidate_version(package_name)
        return options['package_version'] if options['package_version']
        resource = ::Chef::Resource.resource_for_node(:package, node).new(package_name, run_context)
        provider = resource.provider_for_action(install_mode)
        provider.load_current_resource
        provider.send(:candidate_version_array)[0]
      rescue ::Chef::Exceptions::Package
        nil
      end

      def install_mode
        if options['package_upgrade']
          :upgrade
        else
          :install
        end
      end
    end
  end
end
