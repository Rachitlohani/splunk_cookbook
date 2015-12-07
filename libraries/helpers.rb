module Splunk
  module Helpers
    def splunk_home
      if node['splunk']['home']
        node['splunk']['home']
      else
        "/opt/splunk#{node['splunk']['install_type'] == 'forwarder' ? 'forwarder' : ''}"
      end
    end

    def splunk_file(url)
      require 'pathname'
      require 'uri'
      Pathname.new(URI.parse(url).path).basename.to_s
    end

    def splunk_user
      node['splunk']['run_as_root'] ? 'root' : node['splunk']['system_user']['username']
    end

    def splunk_download_url
      prefix = "#{node['splunk']['download_root']}/"\
      "#{node['splunk']['version']}/"\
      "#{node['splunk']['install_type'] == 'server' ? 'splunk' : 'universalforwarder'}/"\
      'linux/'
      splunk_package = "splunk#{node['splunk']['install_type'] == 'server' ? '' : 'forwarder'}"\
      "-#{node['splunk']['version']}"\
      "-#{node['splunk']['build']}"
      suffix = case node['platform']
               when 'centos', 'redhat', 'fedora'
                 node['kernel']['machine'] == 'x86_64' ? '-linux-2.6-x86_64.rpm' : '.i386.rpm'
               when 'debian', 'ubuntu'
                 node['kernel']['machine'] == 'x86_64' ? '-linux-2.6-amd64.deb' : '-linux-2.6-intel.deb'
        end
      prefix + splunk_package + suffix
    end
  end
end
