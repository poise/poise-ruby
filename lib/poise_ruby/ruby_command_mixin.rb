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

require 'poise/utils'
require 'poise_languages'


module PoiseRuby
  # Mixin for resources and providers which run Ruby commands.
  #
  # @since 2.0.0
  module RubyCommandMixin
    include Poise::Utils::ResourceProviderMixin

    module Resource
      include PoiseLanguages::Command::Mixin::Resource(:ruby)

      # @!attribute gem_binary
      #   Path to the gem binary.
      #   @return [String]
      attribute(:gem_binary, kind_of: String, default: lazy { default_gem_binary })

      private

      # Find the default gem binary. If there is a parent use that, otherwise
      # use the same logic as {PoiseRuby::RubyProviders::Base#gem_binary}.
      #
      # @return [String]
      def default_gem_binary
        if parent_ruby
          parent_ruby.gem_binary
        else
          dir, base = ::File.split(ruby)
          # If this ruby is called something weird, bail out.
          raise NotImplementedError unless base.start_with?('ruby')
          # Allow for names like "ruby2.0" -> "gem2.0".
          ::File.join(dir, base.sub(/^ruby/, 'gem'))
        end
      end
    end

    module Provider
      include PoiseLanguages::Command::Mixin::Provider(:ruby)
    end
  end
end
