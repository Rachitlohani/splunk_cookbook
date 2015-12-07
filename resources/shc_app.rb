# Copyright 2011-2016, BBY Solutions, Inc.
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

property :instance_name, String, name_property: true
property :version, String, required: true
property :remote_source, String
property :checksum, String
property :installed, [TrueClass, FalseClass], default: false

default_action :install

load_current_value do
  conf_file = ::File.join(
    splunk_home,
    'etc',
    'shcluster',
    'apps',
    instance_name,
    'default',
    'app.conf')

  version ''
  installed ::File.exist? conf_file

  ::File.open(conf_file).each_line do |line|
    next unless line =~ /^version\s*=/
    version line.split('=')[1].strip!
  end if installed
end

action :install do
  converge_if_changed :version do
    cache_dir      = Chef::Config[:file_cache_path]
    package_file   = "#{instance_name}-#{version}.tgz"
    cached_package = ::File.join(cache_dir, package_file)

    destination = ::File.join(splunk_home, 'etc', 'shcluster', 'apps')
    remote_file cached_package do
      action :create
      source remote_source
      owner splunk_user
      group splunk_user
      mode '0644'
      checksum checksum
    end

    execute 'Extract package_file to shcluster/apps' do
      command "tar xzf #{cached_package}"
      cwd destination
      creates ::File.join(destination, instance_name)
      user splunk_user
      group splunk_user
      action :run
    end
  end
end

action :remove do
  converge_if_changed :installed do
    dir = ::File.join(splunk_home, 'etc', 'shcluster', 'apps', instance_name)
    directory dir do
      recursive true
      action :delete
    end
  end
end
