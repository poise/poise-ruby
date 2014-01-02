#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
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

class Chef
  class Resource::PoiseRuby < Resource
    include Poise
    actions(:upgrade, :install, :remove)

    attribute(:package_name, name_attribute: true)
    attribute(:version, kind_of: String)
  end

  class Provider::PoiseRuby < Provider
    include Poise

    def action_upgrade
      converge_by("upgrade #{new_resource.package_name} from ruby.poise.io") do
        notifying_block do
          install_repository
          upgrade_package
        end
      end
    end

    def action_install
      converge_by("install #{new_resource.package_name} from ruby.poise.io") do
        notifying_block do
          install_repository
          install_package
        end
      end
    end

    def action_remove
      converge_by("remove #{new_resource.package_name} from ruby.poise.io") do
        notifying_block do
          remove_repository
          remove_package
        end
      end
    end

    private

    def install_repository
      if node.platform_family?('rhel')
        install_yum_repository
      elsif node.platform_family?('debian')
        install_apt_repository
      else
        raise "Unsupported platform #{node['platform']}"
      end
    end

    def install_yum_repository
      raise NotImplementedError, 'Not there yet'
    end

    def install_apt_repository
      raise "32-bit packages are not supported" unless node['kernel']['machine'] == 'x86_64'
      codename = if node['lsb']['codename']
        node['lsb']['codename']
      elsif node['platform'] == 'debian' && node['platform_version'].start_with?('6.')
        # Debian 6 doesn't install /etc/lsb-release by default so ohai has no data for it
        'squeeze'
      end
      apt_repository "poise-ruby" do
        uri 'http://ruby.poise.io'
        distribution codename
        components ['main']
        arch 'amd64'
        keyserver 'hkp://pgp.mit.edu'
        key '594F6D7656399B5C'
      end
    end

    def upgrade_package
      package new_resource.package_name do
        action :upgrade
        version new_resource.version
      end
    end

    def install_package
      r = upgrade_package
      r.action(:install)
      r
    end

    def remove_repository
      r = install_repository
      r.action(:remove)
      r
    end

    def remove_package
      r = upgrade_package
      r.action(:remove)
      r
    end

  end
end
