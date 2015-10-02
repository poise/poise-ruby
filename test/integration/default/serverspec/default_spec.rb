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

require 'serverspec'
set :backend, :exec

# Set up the shared example for ruby_runtime_test.
RSpec.shared_examples 'a ruby_runtime_test' do |ruby_name, version=nil|
  let(:ruby_name) { ruby_name }
  let(:ruby_path) { File.join('', 'root', "ruby_test_#{ruby_name}") }
  # Helper for all the file checks.
  def self.assert_file(rel_path, should_exist=true, &block)
    describe rel_path do
      subject { file(File.join(ruby_path, rel_path)) }
      # Do nothing for nil.
      if should_exist == true
        it { is_expected.to be_a_file }
      elsif should_exist == false
        it { is_expected.to_not exist }
      end
      instance_eval(&block) if block
    end
  end

  describe 'ruby_runtime' do
    assert_file('version') do
      its(:content) { is_expected.to start_with version } if version
    end
  end

  describe 'ruby_gem' do
    assert_file('require_thor_before', false)
    assert_file('require_thor_mid')
    assert_file('require_thor_after', false)
    assert_file('sentinel_thor')
    assert_file('sentinel_thor2', false)

    assert_file('sentinel_bundler', false)
  end

  describe 'bundle_install' do
    assert_file('require_hashie') do
      its(:content) { is_expected.to_not eq '' }
    end
    assert_file('require_tomlrb') do
      its(:content) { is_expected.to eq '1.1.0' }
    end
    assert_file('sentinel_thor_bundle', false)
  end

  describe 'bundler + ruby_execute' do
    assert_file('unicorn_version') do
      its(:content) { is_expected.to eq "unicorn v4.9.0\n" }
    end
  end
end # /shared_examples a ruby_runtime_test

describe 'chef provider' do
  it_should_behave_like 'a ruby_runtime_test', 'chef'
end

describe 'system provider', unless: File.exist?('/no_system') do
  it_should_behave_like 'a ruby_runtime_test', 'system'
end

describe 'scl provider', unless: File.exist?('/no_scl') do
  it_should_behave_like 'a ruby_runtime_test', 'scl'
end
