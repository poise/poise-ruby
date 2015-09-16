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

require 'spec_helper'

describe PoiseRuby::RubyProviders::Dummy do
  let(:ruby_runtime) { chef_run.ruby_runtime('test') }
  step_into(:ruby_runtime)
  recipe do
    ruby_runtime 'test' do
      provider :dummy
    end
  end

  describe '#ruby_binary' do
    subject { ruby_runtime.ruby_binary }

    it { is_expected.to eq '/ruby' }
  end # /describe #ruby_binary

  describe '#ruby_environment' do
    subject { ruby_runtime.ruby_environment }

    it { is_expected.to eq({}) }
  end # /describe #ruby_environment

  describe '#gem_binary' do
    subject { ruby_runtime.gem_binary }

    it { is_expected.to eq '/gem' }
  end # /describe #gem_binary

  describe 'action :install' do
    # Just make sure it doesn't error.
    it { run_chef }
  end # /describe action :install

  describe 'action :uninstall' do
    recipe do
      ruby_runtime 'test' do
        action :uninstall
        provider :dummy
      end
    end

    # Just make sure it doesn't error.
    it { run_chef }
  end # /describe action :uninstall
end
