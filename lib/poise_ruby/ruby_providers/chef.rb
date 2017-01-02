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
require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    # Inversion provider for the `ruby_runtime` resource to use whatever Ruby is
    # currently running, generally Chef's omnibus-d Ruby.
    #
    # @since 2.0.0
    # @provides chef
    class ChefRuby < Base
      provides(:chef)

      # The `install` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_install
        # No-op, already installed!
      end

      # The `uninstall` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_uninstall
        raise PoiseRuby::Error.new("You cannot uninstall Chef's Ruby.")
      end

      # The path to the running Ruby binary as determined via RbConfig.
      #
      # @return [String]
      def ruby_binary
        Gem.ruby
      end
    end
  end
end
