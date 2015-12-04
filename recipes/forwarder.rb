#
# Cookbook Name:: splunk
# Recipe:: forwarder
#
# Copyright 2011-2012, BBY Solutions, Inc.
# Copyright 2011-2012, Opscode, Inc.
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
Chef::Recipe.send(:include, Splunk::Helpers)
Chef::Resource.send(:include, Splunk::Helpers)

include_recipe 'splunk::system_user'
include_recipe 'splunk::download_and_install'
include_recipe 'splunk::ftr'
include_recipe 'splunk::update_admin_auth'

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support Search")
else
  role_name = ""
  if node['splunk']['distributed_search'] == true
    role_name = node['splunk']['indexer_role']
  else
    role_name = node['splunk']['server_role']
  end

  splunk_servers = search(:node, "role:#{role_name}")
end

if node['splunk']['ssl_forwarding'] == true
  directory "#{splunk_home}/etc/auth/forwarders" do
    owner splunk_user
    group splunk_user
    action :create
  end

  [node['splunk']['ssl_forwarding_cacert'],node['splunk']['ssl_forwarding_servercert']].each do |cert|
    cookbook_file "#{splunk_home}/etc/auth/forwarders/#{cert}" do
      source "ssl/forwarders/#{cert}"
      owner splunk_user
      group splunk_user
      mode "0755"
      notifies :restart, "service[splunk]"
    end
  end

  # SSL passwords are encrypted when splunk reads the file.  We need to save the password.
  # We need to save the password if it has changed so we don't keep restarting splunk.
  # Splunk encrypted passwords always start with $1$
  ruby_block "Saving Encrypted Password (outputs.conf)" do
    block do
      outputsPass = `grep -m 1 "sslPassword = " #{splunk_home}/etc/system/local/outputs.conf | sed 's/sslPassword = //'`
      if outputsPass.match(/^\$1\$/) && outputsPass != node['splunk']['outputsSSLPass']
        node.default['splunk']['outputsSSLPass'] = outputsPass
      end
    end
    only_if do
      File.exists?("#{splunk_home}/etc/system/local/outputs.conf")
    end
  end
end

template "#{splunk_home}/etc/system/local/outputs.conf" do
  source "forwarder/outputs.conf.erb"
  owner splunk_user
  group splunk_user
  mode "0644"
  variables :splunk_servers => splunk_servers
  notifies :restart, "service[splunk]"
end

["limits"].each do |cfg|
  template "#{splunk_home}/etc/system/local/#{cfg}.conf" do
    source "forwarder/#{cfg}.conf.erb"
    owner splunk_user
    group splunk_user
    mode "0640"
    notifies :restart, "service[splunk]"
   end
end

template "Moving inputs file for role: #{node['splunk']['forwarder_role']}" do
  path "#{splunk_home}/etc/system/local/inputs.conf"
  source "forwarder/#{node['splunk']['forwarder_config_folder']}/#{node['splunk']['forwarder_role']}.inputs.conf.erb"
  owner splunk_user
  group splunk_user
  mode "0640"
  notifies :restart, "service[splunk]"
end
