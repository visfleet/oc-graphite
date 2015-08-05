#
# Cookbook Name:: oc-graphite
# Recipe:: graphite_carbon
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

case node[:platform]
when 'amazon'
  package 'python-carbon'
else
  package 'graphite-carbon'
end

template '/etc/default/graphite-carbon' do
  source 'graphite-carbon.erb'
  mode 0644
  owner 'root'
  group 'root'
end

template '/etc/carbon/carbon.conf' do
  source 'carbon.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
end

template '/etc/carbon/storage-schemas.conf' do
  source 'storage-schemas.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
end

template '/etc/carbon/storage-aggregation.conf' do
  source 'storage-aggregation.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
end

service 'carbon-cache' do
  action [:enable, :start]
  supports :restart => true, :start => true, :stop => true
end
