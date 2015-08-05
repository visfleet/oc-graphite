#
# Cookbook Name:: oc-graphite
# Recipe:: graphite_carbon
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

service 'carbon-cache' do
  action :nothing
  supports :restart => true, :start => true, :stop => true
end

case node[:platform]
when 'amazon'
  bash 'install-ceres' do
    code 'pip install https://github.com/graphite-project/ceres/tarball/master --install-option="--install-scripts=/usr/bin" --install-option="--install-lib=/usr/lib/python2.7/site-packages"'
    not_if { system('pip show -q ceres') }
  end

  bash 'install-whisper' do
    code 'pip install whisper --install-option="--install-scripts=/usr/bin" --install-option="--install-lib=/usr/lib/python2.7/site-packages"'
    not_if { system('pip show -q whisper') }
  end

  bash 'install-carbon' do
    code 'pip install carbon --install-option="--install-scripts=/usr/bin" --install-option="--install-lib=/usr/lib/python2.7/site-packages" --install-option="--install-data=/var/lib/graphite"'
    not_if { system('pip show -q carbon') }
  end

  user '_graphite' do
    home '/var/lib/graphite'
    shell '/sbin/nologin'
    supports manage_home: false
  end

  link '/usr/bin/carbon-cache' do
    to '/usr/bin/carbon-cache.py'
  end

  template '/etc/init.d/carbon-cache' do
    source 'init.d/carbon.erb'
    mode 0755
    owner 'root'
    group 'root'
    notifies :restart, 'service[carbon-cache]', :delayed
  end

else
  package 'graphite-carbon'
end

directory '/var/lib/graphite' do
  owner '_graphite'
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
