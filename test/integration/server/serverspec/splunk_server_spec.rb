require 'serverspec'

set :backend, :exec

describe 'Splunk Server' do
  describe port(80) do
    it { should be_listening }
  end

  describe port(9997) do
    it { should be_listening }
  end

  describe service('splunk') do
    it { should be_running }
  end

  describe file('/volr/splunk') do
    it { should be_directory }
  end

  describe command('/opt/splunk/bin/splunk version') do
    its(:stdout) { should match "Splunk 6.3.1 (build f3e41e4b37b2)\n" }
  end

  ['apache_http', 'useragents'].each do |dashboard|
    describe file("/opt/splunk/etc/users/admin/search/local/data/ui/views/#{dashboard}.xml") do
      it { should exist }
    end
  end

  ['web', 'transforms', 'limits', 'indexes'].each do |conf_file|
    describe file("/opt/splunk/etc/system/local/#{conf_file}.conf") do
      it { should exist }
    end
  end

  ['inputs', 'props'].each do |conf_file|
    describe file("/opt/splunk/etc/system/local/#{conf_file}.conf") do
      it { should exist }
    end
  end
end
