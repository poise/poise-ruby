#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
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
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe file('/opt/ruby-193') do
  it do
    should be_directory
    should be_owned_by('root')
    should be_grouped_into('root')
    should_not be_writable.by('others')
  end
end

describe file('/opt/ruby-193/bin') do
  it do
    should be_directory
    should be_owned_by('root')
    should be_grouped_into('root')
    should_not be_writable.by('others')
  end
end

describe file('/opt/ruby-193/bin/ruby') do
  it { should be_executable }
end

describe file('/opt/ruby-193/bin/gem') do
  it { should be_executable }
end

describe command('/opt/ruby-193/bin/ruby --version') do
  its(:stdout) { should match(/^ruby 1\.9\.3/) }
end

describe command('/opt/ruby-193/bin/gem --version') do
  its(:stdout) { should match(/^1\.8/) }
end
