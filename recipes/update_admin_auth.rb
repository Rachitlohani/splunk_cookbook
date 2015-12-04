Chef::Resource.send(:include, Splunk::Helpers)

user, pw = node['splunk']['auth'].split(':')

file "#{splunk_home}/etc/.setup_#{user}_pwd" do
  owner splunk_user
  group splunk_user
  mode '0600'
  action :nothing
end

execute 'Change default admin password' do
  command "#{splunk_home}/bin/splunk edit user #{user} "\
  "-password #{pw} "\
  '-role admin '\
  '-auth admin:changeme'
  environment 'HOME' => splunk_home
  sensitive true
  notifies :create, "file[#{splunk_home}/etc/.setup_#{user}_pwd]"
  not_if do
    ::File.exist?("#{splunk_home}/etc/.setup_#{user}_pwd") ||
      # So we don't break existing installs
      ::File.exist?('/opt/splunk_setup_passwd')
  end
end

# To clean out the old status file.
file '/opt/splunk_setup_passwd' do
  action :delete
end
