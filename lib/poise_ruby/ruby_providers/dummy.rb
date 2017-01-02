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

require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyProviders
    # Inversion provider for the `ruby_runtime` resource to use a fake Ruby,
    # for use in unit tests.
    #
    # @since 2.1.0
    # @provides dummy
    class Dummy < Base
      provides(:dummy)

      def self.default_inversion_options(node, resource)
        super.merge({
          # Manual overrides for dummy data.
          ruby_binary: ::File.join('', 'ruby'),
          ruby_environment: nil,
          gem_binary: nil,
        })
      end

      # The `install` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_install
        # This space left intentionally blank.
      end

      # The `uninstall` action for the `ruby_runtime` resource.
      #
      # @return [void]
      def action_uninstall
        # This space left intentionally blank.
      end

      # Path to the non-existent ruby.
      #
      # @return [String]
      def ruby_binary
        options['ruby_binary']
      end

      # Environment for the non-existent Ruby.
      #
      # @return [String]
      def ruby_environment
        options['ruby_environment'] || super
      end

      # Path to the non-existent gem.
      #
      # @return [String]
      def gem_binary
        options['gem_binary'] || super
      end

    end
  end
end

