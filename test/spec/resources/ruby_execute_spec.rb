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

describe PoiseRuby::Resources::RubyExecute do
  describe PoiseRuby::Resources::RubyExecute::Resource do
    recipe do
      ruby_execute 'myapp.rb'
    end

    it { is_expected.to run_ruby_execute('myapp.rb') }
  end

  describe PoiseRuby::Resources::RubyExecute::Provider do
    let(:command) { nil }
    let(:environment) { nil }
    let(:ruby) { '/ruby' }
    let(:parent_ruby) { nil }
    let(:parent_bundle) { nil }
    let(:new_resource) do
      double('new_resource',
        command: command,
        environment: environment,
        ruby: ruby,
        parent_ruby: parent_ruby,
        parent_bundle: parent_bundle,
      )
    end
    subject { described_class.new(new_resource, nil) }

    context 'string command' do
      let(:command) { 'myapp.rb' }
      its(:command) { is_expected.to eq '/ruby myapp.rb' }
      its(:environment) { is_expected.to eq({}) }
    end # /context string command

    context 'array command' do
      let(:command) { %w{myapp.rb} }
      its(:command) { is_expected.to eq %w{/ruby myapp.rb} }
      its(:environment) { is_expected.to eq({}) }
    end # /context array command

    context 'with a bundle parent' do
      let(:command) { 'myapp.rb' }
      let(:parent_bundle) { double('parent_bundle', bundler_binary: '/bundle', gemfile_path: '/srv/Gemfile') }
      its(:command) { is_expected.to eq '/ruby /bundle exec myapp.rb' }
      its(:environment) { is_expected.to eq({'BUNDLE_GEMFILE' => '/srv/Gemfile'}) }
    end # /context with a bundle parent

    context 'with a bundle parent and an array command' do
      let(:command) { %w{myapp.rb} }
      let(:parent_bundle) { double('parent_bundle', bundler_binary: '/bundle', gemfile_path: '/srv/Gemfile') }
      its(:command) { is_expected.to eq %w{/ruby /bundle exec myapp.rb} }
      its(:environment) { is_expected.to eq({'BUNDLE_GEMFILE' => '/srv/Gemfile'}) }
    end # /context with a bundle parent and an array command

    context 'with a ruby parent' do
      let(:command) { 'myapp.rb' }
      let(:parent_ruby) { double('parent_ruby', ruby_environment: {'PATH' => '/bin'}) }
      its(:command) { is_expected.to eq '/ruby myapp.rb' }
      its(:environment) { is_expected.to eq({'PATH' => '/bin'}) }
    end # /context with a ruby parent
  end
end
