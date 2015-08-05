#
# Cookbook Name:: oc-graphite
# Recipe:: graphite_web
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

case node[:platform]
when 'amazon'
  bash 'install-graphite-web' do
    code 'pip install graphite-web --install-option="--install-scripts=/usr/bin" --install-option="--install-lib=/usr/lib/python2.7/site-packages" --install-option="--install-data=/var/lib/graphite"'
    not_if { system('pip show -q graphite-web') }
  end

  user '_graphite' do
    home '/var/lib/graphite'
    shell '/sbin/nologin'
    supports manage_home: false
  end

  directory '/var/lib/graphite' do
    owner '_graphite'
  end

  directory '/var/lib/graphite/webapp/graphite' do
    owner 'root'
    recursive true
  end

  template '/var/lib/graphite/webapp/graphite/local_settings.py' do
    source 'local_settings.py.erb'
    mode 0644
    owner 'root'
    group 'root'
  end

else
  package 'graphite-web'

  template '/etc/graphite/local_settings.py' do
    source 'local_settings.py.erb'
    mode 0644
    owner 'root'
    group 'root'
  end

  directory '/var/lib/graphite' do
    owner '_graphite'
  end
end

cookbook_file '/usr/lib/python2.7/dist-packages/django/contrib/auth/management/commands/scriptchangepassword.py' do
  source 'scriptchangepassword.py'
  mode 0644
  owner 'root'
  group 'root'
end

execute 'change_admin_pass' do
  command "graphite-manage scriptchangepassword admin #{node['oc-graphite']['web']['seed_password']}"
  user '_graphite'
  cwd '/var/lib/graphite'
  action :nothing
end

bash 'set_up_db' do
  user '_graphite'
  code <<-EOH
  echo 'start'
  graphite-manage syncdb --noinput
  graphite-manage createsuperuser --noinput --username=admin --email=paul@getchef.com
  EOH

  not_if { ::File.exist? '/var/lib/graphite/graphite.db' }
  notifies :run, 'execute[change_admin_pass]', :delayed
end

include_recipe "oc-graphite::_#{node['oc-graphite']['web']['server']}"
