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
      include Poise(inversion: PoiseRuby::Resources::RubyRuntime::Resource)

      def action_install
        raise NotImplementedError
      end

      def action_uninstall
        raise NotImplementedError
      end

      def bin_dir
        raise NotImplementedError
      end
    end
  end
end
