require 'serverspec'

set :backend, :exec

describe 'Splunk Forwarder' do
  describe service('splunk') do
    it { should be_running }
  end

  describe command('/opt/splunkforwarder/bin/splunk version') do
    its(:stdout) { should match "Splunk Universal Forwarder 6.3.1 (build f3e41e4b37b2)\n" }
  end

  ['outputs', 'limits'].each do |conf_file|
    describe file("/opt/splunkforwarder/etc/system/local/#{conf_file}.conf") do
      it { should exist }
    end
  end
end
