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

require 'chef/provider'
require 'poise'

require 'poise_ruby/resources/ruby_runtime'


module PoiseRuby
  module RubyProviders
    class Base < Chef::Provider
      include Poise(inversion: :ruby_runtime)

      def self.default_inversion_options(node, new_resource)
        super.merge({
          version: new_resource.version,
        })
      end

      # The `install` action for the `ruby_runtime` resource.
      #
      # @abstract
      # @return [void]
      def action_install
        raise NotImplementedError
      end

      # The `uninstall` action for the `ruby_runtime` resource.
      #
      # @abstract
      # @return [void]
      def action_uninstall
        raise NotImplementedError
      end

      # The path to the `ruby` binary.
      #
      # @abstract
      # @return [String]
      def ruby_binary
        raise NotImplementedError
      end

      # The path to the `gem` binary. Look relative to the
      # `ruby` binary for a default implementation.
      #
      # @return [String]
      def gem_binary
        dir, base = ::File.split(ruby_binary)
        # If this ruby is called something weird, bail out.
        raise NotImplementedError unless base.start_with?('ruby')
        # Allow for names like "ruby2.0" -> "gem2.0".
        ::File.join(dir, base.sub(/^ruby/, 'gem'))
      end
    end
  end
end
