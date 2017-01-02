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

require 'chef/platform/provider_priority_map'

require 'poise_ruby/ruby_providers/chef'
require 'poise_ruby/ruby_providers/dummy'
require 'poise_ruby/ruby_providers/scl'
require 'poise_ruby/ruby_providers/system'


module PoiseRuby
  # Inversion providers for the ruby_runtime resource.
  #
  # @since 2.0.0
  module RubyProviders
    Chef::Platform::ProviderPriorityMap.instance.priority(:ruby_runtime, [
      PoiseRuby::RubyProviders::Scl,
      PoiseRuby::RubyProviders::System,
    ])
  end
end
