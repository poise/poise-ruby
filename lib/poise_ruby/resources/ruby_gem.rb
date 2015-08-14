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

require 'chef/provider/package/rubygems'
require 'chef/resource/gem_package'
require 'poise'

require 'poise_ruby/ruby_command_mixin'


module PoiseRuby
  module Resources
    # (see RubyGem::Resource)
    # @since 2.0.0
    module RubyGem
      # A `ruby_gem` resource to install Ruby gems.
      #
      # @provides ruby_gem
      # @action install
      # @action upgrade
      # @action remove
      # @action purge
      # @action reconfig
      # @example
      #   ruby_gem 'rack'
      class Resource < Chef::Resource::GemPackage
        include Poise
        provides(:ruby_gem)
        include PoiseRuby::RubyCommandMixin

        # @api private
        def initialize(name, run_context=nil)
          super
          @resource_name = :ruby_gem if @resource_name
          # Remove when all useful versions are using provider resolver.
          @provider = PoiseRuby::Resources::RubyGem::Provider if @provider
        end
      end

      # The default provider for `ruby_gem`.
      #
      # @see Resource
      # @provides ruby_gem
      class Provider < Chef::Provider::Package::Rubygems
        include Poise
        provides(:ruby_gem)

        def load_current_resource
          patch_environment { super }
        end

        def define_resource_requirements
          patch_environment { super }
        end

        def action_install
          patch_environment { super }
        end

        def action_upgrade
          patch_environment { super }
        end

        def action_remove
          patch_environment { super }
        end

        def action_purge
          patch_environment { super }
        end

        def action_reconfig
          patch_environment { super }
        end

        private

        def patch_environment(&block)
          environment_to_add = if new_resource.parent_ruby
            new_resource.parent_ruby.ruby_environment
          else
            {}
          end

          begin
            old_vars = environment_to_add.inject({}) do |memo, (key, value)|
              memo[key] = ENV[key]
              ENV[key] = value
              memo
            end
            block.call
          ensure
            old_vars.each do |key, value|
              if value.nil?
                ENV.delete(key)
              else
                ENV[key] = value
              end
            end
          end
        end
      end
    end
  end
end
