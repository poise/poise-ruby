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
require 'poise'


module PoiseRuby
  module Resources
    # (see Ruby::Resource)
    # @since 2.0.0
    module Ruby
      # A `ruby` resource to manage Ruby installations.
      #
      # @provides ruby
      # @action install
      # @action uninstall
      # @example
      #   ruby '2.1.2'
      class Resource < Chef::Resource
        include Poise(inversion: true, container: true)
        provides(:ruby)
        actions(:install, :uninstall)

        # @!attribute version
        #   Version of Ruby to install.
        #   @return [String]
        attribute(:version, kind_of: String, name_attribute: true)

        # The binary directory for this Ruby installation. This should
        # contain at least `ruby` and `gem` executables.
        #
        # @return [String]
        # @example
        #   execute "#{resources('ruby[2.2.2]').bin_dir}/ruby myapp.rb"
        def bin_dir
          provider_for_action(:bin_dir).pid
        end
      end

      # Providers can be found under lib/poise_ruby/ruby_providers/
    end
  end
end
