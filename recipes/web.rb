#
# Cookbook Name:: graphite
# Recipe:: web
#
# Copyright 2011, Heavy Water Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "gunicorn"

package "libcairo2-dev"
package "python-cairo-dev"

python_pip "django" do
  version node['graphite']['django_ver']
  action :install
end

%w{python-memcached django-tagging graphite-web}.each do |pkg|
  python_pip pkg do
    action :install
  end
end

basedir = node['graphite']['base_dir']
docroot = node['graphite']['doc_root']
storagedir = node['graphite']['storage_dir']
#version = node['graphite']['version']
#pyver = node['languages']['python']['version'][0..-3]

password = node['graphite']['password']
#if Chef::Config[:solo]
  #Chef::Log.warn "This recipe uses encrypted data bags, which are not supported on Chef Solo - fallback to node attribute."
#elsif node['graphite']['encrypted_data_bag']['name']
  #data_bag_name = node['graphite']['encrypted_data_bag']['name']
  #password = Chef::EncryptedDataBagItem.load(data_bag_name, "graphite")
#else
  #Chef::Log.warn "This recipe uses encrypted data bags for graphite password but no encrypted data bag name is specified - fallback to node attribute."
#end

#%w{ info.log exception.log access.log error.log }.each do |file|
  #file "#{storagedir}/log/webapp/#{file}" do
    #owner node['nginx']['user']
    #group node['nginx']['group']
  #end
#end

template "#{docroot}/graphite/local_settings.py" do
  source "local_settings.py.erb"
  mode 00755
  variables(
    :timezone => node['graphite']['timezone'],
    :base_dir => node['graphite']['base_dir'],
    :doc_root => node['graphite']['doc_root'],
    :storage_dir => node['graphite']['storage_dir']
  )
end

template "#{basedir}/bin/set_admin_passwd.py" do
  source "set_admin_passwd.py.erb"
  mode 00755
end

cookbook_file "#{storagedir}/graphite.db" do
  action :create_if_missing
  notifies :run, "execute[set admin password]"
end

execute "set admin password" do
  command "#{basedir}/bin/set_admin_passwd.py root #{password}"
  action :nothing
end

runit_service "graphite-web" do
  options({
    :address => node['graphite']['django_addr'],
    :port => node['graphite']['django_port'],
    :user => node['nginx']['user'],
    :group => node['nginx']['group'],
    :settings => "#{docroot}/graphite/settings.py"
  })
end

execute "chown #{storagedir}" do
  command "chown -R #{node['nginx']['user']} #{storagedir}"
end

#directory "#{storagedir}" do
  #owner node['nginx']['user']
  #group node['nginx']['group']
  #recursive true
#end

template "#{node['nginx']['dir']}/sites-available/graphite-web" do
  source "graphite-web.erb"
end

nginx_site "default" do
  enable false
end

nginx_site "graphite-web"

## This is not done in the cookbook_file above to avoid triggering a password set on permissions changes
#file "#{storagedir}/graphite.db" do
  #owner node['apache']['user']
  #group node['apache']['group']
  #mode 00644
#end
