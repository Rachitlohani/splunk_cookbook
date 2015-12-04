Chef::Recipe.send(:include, Splunk::Helpers)

user, pw = node['splunk']['auth'].split(':')

home_dir = splunk_home
splunk_user = splunk_user

file "#{home_dir}/etc/.setup_#{user}_pwd" do
  owner splunk_user
  group splunk_user
  mode '0600'
  action :nothing
end

execute 'Change default admin password' do
  command "#{home_dir}/bin/splunk edit user #{user} "\
  "-password #{pw} "\
  '-role admin '\
  '-auth admin:changeme'
  environment 'HOME' => home_dir
  sensitive true
  notifies :create, "file[#{home_dir}/etc/.setup_#{user}_pwd]"
  not_if do
    ::File.exist?("#{home_dir}/etc/.setup_#{user}_pwd") ||
      # So we don't break existing installs
      ::File.exist?('/opt/splunk_setup_passwd')
  end
end
