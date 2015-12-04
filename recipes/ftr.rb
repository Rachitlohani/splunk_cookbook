Chef::Recipe.send(:include, Splunk::Helpers)
Chef::Resource.send(:include, Splunk::Helpers)

home_dir = splunk_home
user = splunk_user

template "#{splunk_home}/etc/splunk-launch.conf" do
  source 'server/splunk-launch.conf.erb'
  mode '0640'
  owner splunk_user
  group splunk_user
  variables(
    splunk_home: splunk_home,
    splunk_db_dir: node['splunk']['db_directory'],
    splunk_user: splunk_user
  )
end

directory 'Create splunk_db directory'do
  path node['splunk']['db_directory']
  owner splunk_user
  group splunk_user
  mode '0700'
  action :create
  recursive true
  only_if { node['splunk']['db_directory'] }
end

ruby_block 'Fix Permissions on Splunk Install Directory' do
  block do
    FileUtils.chown_R splunk_user, splunk_user, splunk_home
  end
end

execute 'Enable Boot Start' do
  command "#{splunk_home}/bin/splunk enable boot-start "\
          "-user #{splunk_user} "\
          '--accept-license --answer-yes'
  only_if { ::File.exist? "#{splunk_home}/ftr" }
end

service 'splunk' do
  supports status: true, start: true, stop: true, restart: true
  action :start
end
