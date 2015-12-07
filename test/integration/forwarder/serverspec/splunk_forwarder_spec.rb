require 'serverspec'

set :backend, :exec

describe 'Splunk Forwarder' do
  describe user('splunk') do
    it { should exist }
    it { should belong_to_group 'splunk' }
    it { should have_uid 396 }
    it { should have_home_directory '/opt/splunkforwarder' }
    it { should have_login_shell '/bin/bash' }
  end

  describe group('splunk') do
    it { should exist }
    it { should have_gid 396 }
  end

  describe service('splunk') do
    it { should be_enabled }
    it { should be_running }
  end

  describe process('splunkd') do
    its(:user) { should match 'root' }
  end

  describe file('/opt/splunkforwarder/etc/splunk-launch.conf') do
    it { should exist }
    it { should be_file }
    its(:content) { should match 'SPLUNK_HOME=/opt/splunkforwarder' }
    its(:content) { should match 'SPLUNK_OS_USER=root' }
  end

  describe file('/opt/splunkforwarder/etc/.setup_admin_pwd') do
    it { should exist }
  end

  describe file('/opt/splunk_setup_passwd') do
    it { should_not exist }
  end

  describe file('/opt/splunkforwarder/etc/splunk.version') do
    it { should exist }
    its(:content) { should match 'VERSION=6.3.1' }
    its(:content) { should match 'BUILD=f3e41e4b37b2' }
  end

  describe file('/opt/splunkforwarder/etc/system/local/server.conf') do
    its(:content) { should match 'serverName = splunk-forwarder.local-splunk' }
  end

  %w(outputs limits).each do |conf_file|
    describe file("/opt/splunkforwarder/etc/system/local/#{conf_file}.conf") do
      it { should exist }
    end
  end
end
