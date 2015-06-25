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
require 'poise_languages'

require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    class Scl < Base
      include PoiseLanguages::SclProviderMixin
      provides(:scl)
      scl_package('2.2.2', 'rh-ruby22', {
        ['rhel', 'centos'] => {
          '~> 7.0' => 'https://www.softwarecollections.org/en/scls/rhscl/rh-ruby22/epel-7-x86_64/download/rhscl-rh-ruby22-epel-7-x86_64.noarch.rpm',
          '~> 6.0' => 'https://www.softwarecollections.org/en/scls/rhscl/rh-ruby22/epel-6-x86_64/download/rhscl-rh-ruby22-epel-6-x86_64.noarch.rpm',
        },
      })
      scl_package('2.0.0', 'ruby200', {
        ['rhel', 'centos'] => {
          # On CentOS 7, the system package is Ruby 2.0.0 and is newer than the SCL build.
          #'~> 7.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby200/epel-7-x86_64/download/rhscl-ruby200-epel-7-x86_64.noarch.rpm',
          '~> 6.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby200/epel-6-x86_64/download/rhscl-ruby200-epel-6-x86_64.noarch.rpm',
        },
        'fedora' => {
          '~> 21.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby200/fedora-21-x86_64/download/rhscl-ruby200-fedora-21-x86_64.noarch.rpm',
          '~> 20.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby200/fedora-20-x86_64/download/rhscl-ruby200-fedora-20-x86_64.noarch.rpm',
        },
      })
      scl_package('1.9.3', 'ruby193', {
        ['rhel', 'centos'] => {
          '~> 7.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby193/epel-7-x86_64/download/rhscl-ruby193-epel-7-x86_64.noarch.rpm',
          '~> 6.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby193/epel-6-x86_64/download/rhscl-ruby193-epel-6-x86_64.noarch.rpm',
        },
        'fedora' => {
          '~> 21.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby193/fedora-21-x86_64/download/rhscl-ruby193-fedora-21-x86_64.noarch.rpm',
          '~> 20.0' => 'https://www.softwarecollections.org/en/scls/rhscl/ruby193/fedora-20-x86_64/download/rhscl-ruby193-fedora-20-x86_64.noarch.rpm',
        },
      })

      def ruby_binary
        ::File.join(scl_folder, 'root', 'usr', 'bin', 'ruby')
      end

      def ruby_environment
        scl_environment
      end

    end
  end
end

