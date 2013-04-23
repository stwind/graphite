#
# Cookbook Name:: graphite
# Recipe:: carbon
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

#package "python-twisted"

if node['graphite']['carbon']['enable_amqp']
    package "python-txamqp"
end

python_pip "simplejson" do
  action :install
end

version = node['graphite']['version']
#pyver = node['languages']['python']['version'][0..-3]

python_pip "carbon" do
  version version
  action :install
end

template "#{node['graphite']['base_dir']}/conf/carbon.conf" do
  owner node['nginx']['user']
  group node['nginx']['group']
  variables( :line_receiver_interface => node['graphite']['carbon']['line_receiver_interface'],
             :line_receiver_port => node['graphite']['carbon']['line_receiver_port'],
             :pickle_receiver_interface => node['graphite']['carbon']['pickle_receiver_interface'],
             :pickle_receiver_port => node['graphite']['carbon']['pickle_receiver_port'],
             :cache_query_interface => node['graphite']['carbon']['cache_query_interface'],
             :cache_query_port => node['graphite']['carbon']['cache_query_port'],
             :max_cache_size => node['graphite']['carbon']['max_cache_size'],
             :max_updates_per_second => node['graphite']['carbon']['max_updates_per_second'],
             :max_creates_per_second => node['graphite']['carbon']['max_creates_per_second'],
             :log_whisper_updates => node['graphite']['carbon']['log_whisper_updates'],
             :enable_amqp => node['graphite']['carbon']['enable_amqp'],
             :amqp_host => node['graphite']['carbon']['amqp_host'],
             :amqp_port => node['graphite']['carbon']['amqp_port'],
             :amqp_vhost => node['graphite']['carbon']['amqp_vhost'],
             :amqp_user => node['graphite']['carbon']['amqp_user'],
             :amqp_password => node['graphite']['carbon']['amqp_password'],
             :amqp_exchange => node['graphite']['carbon']['amqp_exchange'],
             :amqp_metric_name_in_body => node['graphite']['carbon']['amqp_metric_name_in_body'],
             :storage_dir => node['graphite']['storage_dir'])
  notifies :restart, "service[carbon-cache]"
end

#Chef::Log.info resources(:service => "carbon-cache")

template "#{node['graphite']['base_dir']}/conf/storage-schemas.conf" do
  owner node['nginx']['user']
  group node['nginx']['group']
  variables({
    :schemas => node['graphite']['carbon']['schemas']
  })
  notifies :restart, "service[carbon-cache]"
end

directory node['graphite']['storage_dir'] do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
end

directory "#{node['graphite']['storage_dir']}/whisper" do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
end

directory "#{node['graphite']['base_dir']}/lib/twisted/plugins/" do
  owner node['nginx']['user']
  group node['nginx']['group']
  recursive true
end

service_type = node['graphite']['carbon']['service_type']
include_recipe "#{cookbook_name}::#{recipe_name}_#{service_type}"
