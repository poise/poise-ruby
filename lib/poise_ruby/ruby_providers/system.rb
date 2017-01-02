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
require 'poise_languages'

require 'poise_ruby/error'
require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    class System < Base
      include PoiseLanguages::System::Mixin
      provides(:system)
      packages('ruby', {
        debian: {
          '8' => %w{ruby2.1},
          '7' => %w{ruby1.9.3 ruby1.9.1 ruby1.8},
           # Debian 6 has a ruby1.9.1 package that installs 1.9.2, ignoring it for now.
          '6' => %w{ruby1.8},
        },
        ubuntu: {
          '16.04' => %w{ruby2.3},
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
      })

      def self.default_inversion_options(node, resource)
        super.merge({
          # Install a separate rubygems package? Only needed for 1.8.
          rubygems_package: node['platform_family'] == 'rhel' && node['platform_version'].start_with?('6'),
        })
      end

      # Output value for the Python binary we are installing. Seems to match
      # package name on all platforms I've checked.
      def ruby_binary
        ::File.join('', 'usr', 'bin', system_package_name)
      end

      private

      def install_ruby
        install_system_packages
        install_rubygems_package if options['rubygems_package']
      end

      def uninstall_ruby
        uninstall_system_packages
      end

      # Ubuntu has no ruby1.9.3-dev package.
      def system_dev_package_overrides
        super.tap do |overrides|
          # WTF Ubuntu, seriously.
          overrides['ruby1.9.3'] = 'ruby1.9.1-dev' if node.platform_family?('debian')
        end
      end

      # Install the configured rubygems package.
      def install_rubygems_package
        package (options['rubygems_package'].is_a?(String) ? options['rubygems_package'] : 'rubygems')
      end

      def system_package_candidates(version)
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
