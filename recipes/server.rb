#
# Cookbook Name::splunk
# Recipe::server
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
include_recipe 'splunk::system_user'
include_recipe 'splunk::download_and_install'
include_recipe 'splunk::ftr'
include_recipe 'splunk::update_admin_auth'

home_dir = splunk_home
splunk_cmd = "#{home_dir}/bin/splunk"

# True for both a Dedicated Search head for Distributed Search and for non-distributed search
dedicated_search_head = true
# Only true if we are a dedicated indexer AND are doing a distributed search setup
dedicated_indexer = false
# True only if our public ip matches what we set the master to be
search_master = (node['splunk']['dedicated_search_master'] == node['ipaddress']) ? true : false

if node['splunk']['distributed_search'] == true
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
    # Add the Distributed Search Template
    node.normal['splunk']['static_server_configs'] << "distsearch"

    # We are a search head
    if node.run_list.include?("role[#{node['splunk']['server_role']}]")
      search_indexers = search(:node, "role:#{node['splunk']['indexer_role']}")
      # Add an outputs.conf.  Search Heads should not be doing any indexing
      node.normal['splunk']['static_server_configs'] << "outputs"
    else
      dedicated_search_head = false
    end

    # we are a dedicated indexer
    if node.run_list.include?("role[#{node['splunk']['indexer_role']}]")
      # Find all search heads so we can move their trusted.pem files over
      search_heads = search(:node, "role:#{node['splunk']['server_role']}")
      dedicated_indexer = true
    end
  end
end

if node['splunk']['use_ssl'] == true && dedicated_search_head == true

  directory "#{home_dir}/ssl" do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
  end

  cookbook_file "#{home_dir}/ssl/#{node['splunk']['ssl_crt']}" do
    source "ssl/#{node['splunk']['ssl_crt']}"
    mode "0755"
    owner "root"
    group "root"
  end

  cookbook_file "#{home_dir}/ssl/#{node['splunk']['ssl_key']}" do
    source "ssl/#{node['splunk']['ssl_key']}"
    mode "0755"
    owner "root"
    group "root"
  end

end

if node['splunk']['ssl_forwarding'] == true

  # Create the SSL Cert Directory for the Forwarders
  directory "#{home_dir}/etc/auth/forwarders" do
    owner "root"
    group "root"
    action :create
    recursive true
  end

  # Copy over the SSL Certs
  [node['splunk']['ssl_forwarding_cacert'],node['splunk']['ssl_forwarding_servercert']].each do |cert|
    cookbook_file "#{home_dir}/etc/auth/forwarders/#{cert}" do
      source "ssl/forwarders/#{cert}"
      owner "root"
      group "root"
      mode "0755"
      notifies :restart, "service[splunk]"
    end
  end

  # SSL passwords are encrypted when splunk reads the file.  We need to save the password.
  # We need to save the password if it has changed so we don't keep restarting splunk.
  # Splunk encrypted passwords always start with $1$
  ruby_block "Saving Encrypted Password (inputs.conf/outputs.conf)" do
    block do
      inputsPass = `grep -m 1 "password = " #{home_dir}/etc/system/local/inputs.conf | sed 's/password = //'`
      if inputsPass.match(/^\$1\$/) && inputsPass != node['splunk']['inputsSSLPass']
        node.normal['splunk']['inputsSSLPass'] = inputsPass
        node.save
      end

      if node['splunk']['distributed_search'] == true && dedicated_search_head == true
          outputsPass = `grep -m 1 "sslPassword = " #{home_dir}/etc/system/local/outputs.conf | sed 's/sslPassword = //'`

          if outputsPass.match(/^\$1\$/) && outputsPass != node['splunk']['outputsSSLPass']
            node.normal['splunk']['outputsSSLPass'] = outputsPass
            node.save
          end
        end
    end
  end
end

if node.run_list.roles.include?(node['splunk']['server_role'])
  splunk_dir = home_dir
else
  splunk_dir = node['splunk']['forwarder_home']
end

# Enable receiving ports only if we are a standalone installation or a dedicated_indexer
if dedicated_indexer == true || node['splunk']['distributed_search'] == false
  execute "Enabling Receiver Port #{node['splunk']['receiver_port']}" do
    command "#{splunk_cmd} enable listen #{node['splunk']['receiver_port']} -auth #{node['splunk']['auth']}"
    not_if "grep splunktcp:#{node['splunk']['receiver_port']} #{home_dir}/etc/system/local/inputs.conf"
  end
end

if node['splunk']['scripted_auth'] == true && dedicated_search_head == true
  # Be sure to deploy the authentication template.
  node.normal['splunk']['static_server_configs'] << "authentication"

  if !node['splunk']['data_bag_key'].empty?
    scripted_auth_creds = Chef::EncryptedDataBagItem.load(node['splunk']['scripted_auth_data_bag_group'], node['splunk']['scripted_auth_data_bag_name'], node['splunk']['data_bag_key'])
  else
    scripted_auth_creds = { "user" => "", "password" => ""}
  end

  directory "#{home_dir}/#{node['splunk']['scripted_auth_directory']}" do
    recursive true
    action :create
  end

  node['splunk']['scripted_auth_files'].each do |auth_file|
    cookbook_file "#{home_dir}/#{node['splunk']['scripted_auth_directory']}/#{auth_file}" do
      source "scripted_auth/#{auth_file}"
      owner "root"
      group "root"
      mode "0755"
      action :create
    end
  end

  node['splunk']['scripted_auth_templates'].each do |auth_templ|
    template "#{home_dir}/#{node['splunk']['scripted_auth_directory']}/#{auth_templ}" do
      source "server/scripted_auth/#{auth_templ}.erb"
      owner "root"
      group "root"
      mode "0744"
      variables(
        :user => scripted_auth_creds['user'],
        :password => scripted_auth_creds['password']
      )
    end
  end
end

node['splunk']['static_server_configs'].each do |cfg|
  template "#{home_dir}/etc/system/local/#{cfg}.conf" do
    source "server/#{cfg}.conf.erb"
    owner "root"
    group "root"
    mode "0640"
    variables(
        :search_heads => search_heads,
        :search_indexers => search_indexers,
        :dedicated_search_head => dedicated_search_head,
        :dedicated_indexer => dedicated_indexer
      )
    notifies :restart, "service[splunk]"
  end
end

node['splunk']['dynamic_server_configs'].each do |cfg|
  template "#{home_dir}/etc/system/local/#{cfg}.conf" do
    source "server/#{node['splunk']['server_config_folder']}/#{cfg}.conf.erb"
    owner "root"
    group "root"
    mode "0640"
    notifies :restart, "service[splunk]"
   end
end



directory "#{home_dir}/etc/users/admin/search/local/data/ui/views" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

if node['splunk']['deploy_dashboards'] == true
  node['splunk']['dashboards_to_deploy'].each do |dashboard|
    cookbook_file "#{home_dir}/etc/users/admin/search/local/data/ui/views/#{dashboard}.xml" do
      source "dashboards/#{dashboard}.xml"
    end
  end
end

if node['splunk']['distributed_search'] == true
  # We are not the search master.. we need to link up to the master for our license information
  if search_master == false
    execute "Linking license to search master" do
      command "#{splunk_cmd} edit licenser-localslave -master_uri 'https://#{node['splunk']['dedicated_search_master']}:8089' -auth #{node['splunk']['auth']}"
      not_if "grep \"master_uri = https://#{node['splunk']['dedicated_search_master']}:8089\" #{home_dir}/etc/system/local/server.conf"
    end
  end

  if dedicated_search_head == true
    # We save this information so we can reference it on indexers.
    ruby_block "Splunk Server - Saving Info" do
      block do
        splunk_server_name = `grep -m 1 "serverName = " #{home_dir}/etc/system/local/server.conf | sed 's/serverName = //'`
        splunk_server_name = splunk_server_name.strip

        if File.exists?("#{home_dir}/etc/auth/distServerKeys/trusted.pem")
          trustedPem = IO.read("#{home_dir}/etc/auth/distServerKeys/trusted.pem")
          if node['splunk']['trustedPem'] == nil || node['splunk']['trustedPem'] != trustedPem
            node.default['splunk']['trustedPem'] = trustedPem
            node.save
          end
        end

        if node['splunk']['splunkServerName'] == nil || node['splunk']['splunkServerName'] != splunk_server_name
          node.default['splunk']['splunkServerName'] = splunk_server_name
          node.save
        end
      end
    end
  end

  if dedicated_indexer == true
    search_heads.each do |server|
      if server['splunk'] != nil && server['splunk']['trustedPem'] != nil && server['splunk']['splunkServerName'] != nil
        directory "#{home_dir}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}" do
          owner "root"
          group "root"
          action :create
        end

        file "#{home_dir}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}/trusted.pem" do
          owner "root"
          group "root"
          mode "0600"
          content server['splunk']['trustedPem'].strip
          action :create
          notifies :restart, "service[splunk]"
        end
      end
    end
  end
end # End of distributed search

