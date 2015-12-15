Attributes
===========

default
-------
* `node['splunk']['cookbook_name']` - The name of the directory in which the cookbook runs.
* `node['splunk']['install_type']` - Basic install type.  (`server` or `forwarder`)
* `node['splunk']['hostname']` - How the Splunk server identifies itself in REST calls, and the default hostname for inputs.conf
* `node['splunk']['run_as_root']` - Should splunk run as root user
* `node['splunk']['system_user']` - System user Splunk should run as
	- `node['splunk']'system_user']['username']`
	- `node['splunk']['system_user']['comment']`
	- `node['splunk']['system_user']['shell']`
	- `node['splunk']['system_user']['uid']`
	- NOTE:  User home directory will be set to $SPLUNK_HOME
* `node['splunk']['home']` - The directory in which to install the Splunk Server
	- if nil, uses default splunk install location.
	- Note, this attribute, and the previous `server_home`/`forwarder_home` do not actually alter the Splunk install directory.  Changing them likely just breaks things.
	- Replaces `node['splunk']['server_home']` and `node['splunk']['forwarder_home']`
* `node['splunk']['server_home']` - DEPRECATED - The directory in which to install the Splunk Server
* `node['splunk']['db_directory']` - The directory to use for the Splunk Server Database.
	- If nil, uses splunk default location (`$SPLUNK_HOME/var/lib/splunk`)

* `node['splunk']['web_server_port']` - The port number to assign the web server (httpport).
	- File location: templates/server/web.conf.erb
* `node['splunk']['root_endpoint']` - The endpoint for the splunk web instance
* `node['splunk']['browser_timeout']` - The inactivity timeout (ui_inactivity_timeout).
	- File location: templates/server/web.conf.erb
* `node['splunk']['minify_js']` - Indicates whether the static JS files for modules are consolidated and minified.
	- File location: templates/server/web.conf.erb
* `node['splunk']['minify_css']` - Indicates whether the static CSS files for modules are consolidated and minified.
	- File location: templates/server/web.conf.erb

* `node['splunk']['use_ssl']` - Toggles between http or https (enableSplunkWebSSL).
	- File location: templates/server/web.conf.erb
* `node['splunk']['ssl_crt']` - The cert file name if you are using the SSL web frontend.
	- File location: files/default/ssl
* `node['splunk']['ssl_key']` - The private key file if you are using the SSL web frontend.
	- File location: files/default/ssl

* `node['splunk']['deploy_dashboards']` - Toggles deploying dashboards or not
* `node['splunk']['dashboards_to_deploy']` - An array of xml dashboards to copy over. These are the filenames minus the .xml suffix.
	- File location: files/default/dashboards

* `node['splunk']['server_config_folder']` - The folder which contains the environment specific server config files.  It is best to override this attribute per chef role.
	- Folder Location: templates/server/#{node['splunk']['server_config_folder']}
* `node['splunk']['static_server_configs']` - An array of static server configs that *are not* specific to an environment (Dev, QA, PL, Prod, etc).  These are the primary names without the .conf.erb suffix.
	- File Locations: templates/server
* `node['splunk']['dynamic_server_configs']` - An array of dynamic server configs that *are* specific to an environment.  These are the primary names without the .conf.erb suffix.
	- File Location: templates/server/#{node['splunk']['server_config_folder']}

* `node['splunk']['receiver_port']` - The default port in which to receive data from the forwarders.

* `node['splunk']['auth']` - The default admin password to use instead of splunks "changeme"

* `node['splunk']['server_role']` - The role name of the splunk standalone install / dedicated search head.  Forwarders will search for this role in order to identify the server in which to send the data.
* `node['splunk']['indexer_role']` - The role name of the splunk indexer if using dedicated searching

* `node['splunk']['max_searches_per_cpu']` - The max searches per cpu (limits.conf)

Forwarding and Receiving
------------------------
* `node['splunk']['forwarding']['compressed']` - Indicate if data should be compressed when forwarding.  Only applicable when not using ssl.  Sets this on both forwarders and receivers.
* `node['splunk']['forwarding']['indexers']` - For forwarders:  All valid targets the node should forward data to.  This is expected to be an array of addresses.  Examples: `['192.168.1.1','192.168.1.2']` or ['splunkindexer1.mydomain.com', 'splunkindxer2.mydomain.com']
* `node['splunk']['forwarding']['port']` - Which port should be used for splunk forwarding.  Used in configuring both forwarders and receivers.
* `node['splunk']['forwarding']['ssl']['enable']` - Enable SSL forwarding.  If none of the following attributes are set, uses the built-in self-signed certs.
* `node['splunk']['forwarding']['ssl']['cacert']` - path to custom root CA cert.
* `node['splunk']['forwarding']['ssl']['servercert']` - Path to custom server cert.
* `node['splunk']['forwarding']['ssl']['password']` - certificate password
* `node['splunk']['forwarding']['ssl']['requireClientCert']` - Indicates if an indexer should expect the client to authenticate using the SSL cert.  Default to false when using self-signed certs.
* `node['splunk']['forwarding']['ssl']['sslVerifyServerCert']` - Indicates if a forwarder should check if the receiver is valid.  Defaults to 'false' when using self-signed certs.


distributed_search
------------------
* `node['splunk']['distributed_search']` - Enable/Disable distributed search
* `node['splunk']['distributed_search_master']` - The local IP of the License Master

forwarder
---------
* `node['splunk']['forwarder_home']` - DEPRECATED - The directory in which to install the Splunk Forwarder

* `node['splunk']['forwarder_role']` - The name of the splunk forwarder role.  It is best to override this attribute per role.  This is the inputs file that will be moved over on the forwarding server.
	- File Location: templates/forwarder/#{node['splunk']['forwarder_config_folder']}/#{node['splunk']['forwarder_role']}.inputs.conf.erb
* `node['splunk']['forwarder_config_folder']` - The folder which contains the inputs file for the environment.  It is best to override this attribute per chef role.
	- Folder Location: templates/forwarder/#{node['splunk']['forwarder_config_folder']}
* `node['splunk']['limits_thruput']` - The max amount of bandwidth, in KBps, the forwarders will use when sending data.
	- File Location: templates/forwarder/limits.conf.erb

indexes
-------
* `node['splunk']['indexes']` - Hash of index information.  Each key is a corresponding key in indexes.conf

scripted_auth
-------------

* `node['splunk']['scripted_auth']` - Enable Scripted Authentcation
* `node['splunk']['scripted_auth_directory']` - The directory to place the authentication scripts.  This is appended to the base install directory

* `node['splunk']['scripted_auth_files'] ` - An array of static cookbook files to deploy.
	- File Location: files/default/scripted_auth
	- Deployed to: `node['splunk']['scripted_auth_directory']`
* `node['splunk']['scripted_auth_templates']` - An array of templates to deploy.
	- File Location: templates/default/server/scripted_auth
	- Deployed to: `node['splunk']['scripted_auth_directory']`
* `node['splunk']['scripted_auth_script']` - The main script that will be called for authentication

* `node['splunk']['scripted_auth_userLoginTTL']` - TTL to cache user login information
* `node['splunk']['scripted_auth_getUserInfoTTL']` - TTL to cache user information
* `node['splunk']['scripted_auth_getUsersTTL']` - TTL to cache all user information

* `node['splunk']['scripted_auth_data_bag_group']` - The data bag group (if using data bags to deploy user/passwords in your auth file)
* `node['splunk']['scripted_auth_data_bag_name']` - The data bag name (if using data bags to deploy user/passwords in your auth file)
* `node['splunk']['data_bag_key']` - The data bag secret key.

versions
--------
* `node['splunk']['download_root']` - The base URL that splunk uses to download release files for Splunk Server
* `node['splunk']['version']` - The specific version of Splunk Server to download
* `node['splunk']['build']` - the specific build number of Splunk to download
* `node['splunk']['remote_url']` - Use if getting installers from a custom location.
	- Simply provide full URL to download location
* `node['splunk']['server_root']` - DEPRECATED - The base URL that splunk uses to download release files for Splunk Server
* `node['splunk']['server_version']` - DEPRECATED - The specific version of Splunk Server to download
* `node['splunk']['server_build]` - DEPRECATED - The specific build number of Splunk Server to download

* `node['splunk']['forwarder_root']` - DEPRECATED - The base URL that splunk uses to download release files for Splunk Forwarder
* `node['splunk']['forwarder_version']` - DEPRECATED - The specific version of Splunk Forwarder to download
* `node['splunk']['forwarder_build]` - DEPRECATED - The specific build number of Splunk Forwarder to download


License and Author
==================

Author:: Bryan Brandau (<bryan.brandau@bestbuy.com>)
Author:: Andrew Painter (<andrew.painter@bestbuy.com>)
Author:: Aaron Peterson (<aaron@opscode.com>)

Copyright 2011-2012, BBY Solutions, Inc.
Copyright 2011-2012, Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
