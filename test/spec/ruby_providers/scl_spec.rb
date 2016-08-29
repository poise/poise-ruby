#
# Copyright 2015-2016, Noah Kantrowitz
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

describe PoiseRuby::RubyProviders::Scl do
  let(:ruby_version) { '' }
  let(:chefspec_options) { {platform: 'centos', version: '7.0'} }
  let(:default_attributes) { {poise_ruby_version: ruby_version} }
  let(:ruby_runtime) { chef_run.ruby_runtime('test') }
  step_into(:ruby_runtime)
  recipe do
    ruby_runtime 'test' do
      provider :scl
      version node['poise_ruby_version']
    end
  end

  shared_examples_for 'scl provider' do |pkg|
    it { expect(ruby_runtime.provider_for_action(:install)).to be_a described_class }
    it { expect(ruby_runtime.ruby_binary).to eq File.join('', 'opt', 'rh', pkg, 'root', 'usr', 'bin', 'ruby') }
    it { is_expected.to install_poise_languages_scl(pkg) }
    it do
      expect_any_instance_of(described_class).to receive(:install_scl_package)
      run_chef
    end
    it do
      expect_any_instance_of(described_class).to receive(:scl_environment)
      ruby_runtime.ruby_environment
    end
  end

  context 'with version ""' do
    let(:ruby_version) { '' }
    it_behaves_like 'scl provider', 'rh-ruby23'
  end # /context with version ""

  context 'with version "2.2"' do
    let(:ruby_version) { '2.2' }
    it_behaves_like 'scl provider', 'rh-ruby22'
  end # /context with version "2.2"

  context 'with version "2"' do
    let(:ruby_version) { '2' }
    it_behaves_like 'scl provider', 'rh-ruby23'
  end # /context with version "2"


  context 'with version "" on CentOS 6' do
    let(:chefspec_options) { {platform: 'centos', version: '6.0'} }
    let(:ruby_version) { '' }
    it_behaves_like 'scl provider', 'rh-ruby22'
  end # /context with version "" on CentOS 6

  context 'action :uninstall' do
    recipe do
      ruby_runtime 'test' do
        action :uninstall
        provider :scl
        version node['poise_ruby_version']
      end
    end

    it do
      expect_any_instance_of(described_class).to receive(:uninstall_scl_package)
      run_chef
    end
    it { expect(ruby_runtime.provider_for_action(:uninstall)).to be_a described_class }
  end # /context action :uninstall
end
