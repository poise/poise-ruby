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

require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    class Scl < Base
      include PoiseLanguages::Scl::Mixin
      provides(:scl)
      scl_package('2.4.0', 'rh-ruby24', 'rh-ruby24-ruby-devel')
      scl_package('2.3.1', 'rh-ruby23', 'rh-ruby23-ruby-devel')
      scl_package('2.2.2', 'rh-ruby22', 'rh-ruby22-ruby-devel')
      # On EL7, the system package is Ruby 2.0.0 and is newer than the SCL build.
      scl_package('2.0.0', 'ruby200', 'ruby200-ruby-devel', '~> 6.0')
      scl_package('1.9.3', 'ruby193', 'ruby193-ruby-devel')

      def ruby_binary
        ::File.join(scl_folder, 'root', 'usr', 'bin', 'ruby')
      end

      def ruby_environment
        scl_environment
      end

      private

      def install_ruby
        install_scl_package
      end

      def uninstall_ruby
        uninstall_scl_package
      end

    end
  end
end

