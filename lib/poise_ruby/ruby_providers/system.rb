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
        })
      end

      def action_install
        candidate = find_candidate
        notifying_block do
          install_package(candidate)
          install_dev_package(candidate) if options['dev_package']
          install_rubygems_package if options['rubygems_package']
        end
      end

      def action_uninstall
        candidate = find_candidate
        notifying_block do
          remove_package(candidate)
          remove_dev_package(candidate) if options['dev_package']
          remove_rubygems_package if options['rubygems_package']
        end
      end

      def ruby_binary
        ::File.join('', 'usr', 'bin', find_candidate[:name])
      end

      def install_mode
        if options['package_upgrade']
          :upgrade
        else
          :install
        end
      end

      private

      def install_package(candidate)
        package candidate[:name] do
          action install_mode
          version candidate[:version]
        end
      end

      def install_dev_package(candidate)
        suffix = node.value_for_platform_family(debian: '-dev', rhel: '-devel')
        # Platforms like Arch and Gentoo don't need this anyway.
        return unless suffix
        dev_package_name = candidate[:name] + suffix
        if dev_package_name == 'ruby1.9.3-dev'
          # WTF Ubuntu, seriously.
          dev_package_name = 'ruby1.9.1-dev'
        end
        package dev_package_name do
          action install_mode
          version candidate[:version]
        end
      end

      def install_rubygems_package
        package 'rubygems' do
          action install_mode
        end
      end

      def remove_package(candidate)
        install_package(candidate).tap do |r|
          # Try to purge if on debian-ish.
          r.action(node.platform_family?('debian') ? :purge : :remove)
        end
      end

      def remove_dev_package(candidate)
        install_dev_package(candidate).tap do |r|
          # Try to purge if on debian-ish.
          r.action(node.platform_family?('debian') ? :purge : :remove) if r
        end
      end

      def remove_rubygems_package
        install_rubygems_package.tap do |r|
          # Try to purge if on debian-ish.
          r.action(node.platform_family?('debian') ? :purge : :remove)
        end
      end

      def find_candidate
        names = if options['package_name']
          [options['package_name']]
        else
          candiate_names(options['version'])
        end
        names.each do |name|
          version = candidate_version(name)
          Chef::Log.debug("[#{new_resource}] Found candidate version #{version.inspect} for package #{name}")
          # Trim epoch bullshit.
          if version && version.sub(/^\d:/, '').start_with?(options['version'])
            return {name: name, version: version}
          end
        end
        # No valid candidate. Sad trombone.
        raise PoiseRuby::Error.new("Unable to find a candidate package for Ruby version #{options['version']}")
      end

      def candiate_names(version)
        version ||= '' # Mildly sane default.
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
          names << "ruby"
          names.uniq!
        end
      end

      def candidate_version(package_name)
        return options['package_version'] if options['package_version']
        resource = Chef::Resource.resource_for_node(:package, node).new(package_name, run_context)
        provider = resource.provider_for_action(install_mode)
        provider.load_current_resource
        provider.send(:candidate_version_array)[0]
      rescue Chef::Exceptions::Package
        nil
      end


    end
  end
end
