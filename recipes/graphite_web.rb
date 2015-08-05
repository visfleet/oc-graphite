#
# Cookbook Name:: oc-graphite
# Recipe:: graphite_web
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

graphite_manage = ''

case node[:platform]
when 'amazon'
  bash 'install-django' do
    code 'pip install django --target="/usr/lib/python2.7/site-packages"'
    not_if { system('pip show -q django') }
  end

  bash 'install-django-tagging' do
    code 'pip install django-tagging --target="/usr/lib/python2.7/site-packages"'
    not_if { system('pip show -q django-tagging') }
  end

  bash 'install-graphite-web' do
    code 'pip install graphite-web --install-option="--install-scripts=/usr/bin" --install-option="--install-lib=/usr/lib/python2.7/site-packages" --install-option="--install-data=/var/lib/graphite"'
    not_if { system('pip show -q graphite-web') }
  end

  user '_graphite' do
    home '/var/lib/graphite'
    shell '/sbin/nologin'
    supports manage_home: false
  end

  template '/usr/lib/python2.7/site-packages/graphite/local_settings.py' do
    source 'local_settings.py.erb'
    mode 0644
    owner 'root'
    group 'root'
  end

  cookbook_file '/usr/lib/python2.7/site-packages/django/contrib/auth/management/commands/scriptchangepassword.py' do
    source 'scriptchangepassword.py'
    mode 0644
    owner 'root'
    group 'root'
  end

  graphite_manage = '/usr/lib/python2.7/site-packages/django/bin/django-admin.py'

else
  package 'graphite-web'

  template '/etc/graphite/local_settings.py' do
    source 'local_settings.py.erb'
    mode 0644
    owner 'root'
    group 'root'
  end

  cookbook_file '/usr/lib/python2.7/dist-packages/django/contrib/auth/management/commands/scriptchangepassword.py' do
    source 'scriptchangepassword.py'
    mode 0644
    owner 'root'
    group 'root'
  end

  graphite_manage = 'graphite-manage'
end

directory '/var/lib/graphite' do
  owner '_graphite'
end

execute 'change_admin_pass' do
  command "#{graphite_manage} scriptchangepassword admin #{node['oc-graphite']['web']['seed_password']} --settings=graphite.settings"
  user '_graphite'
  cwd '/var/lib/graphite'
  action :nothing
end

bash 'set_up_db' do
  user '_graphite'
  code <<-EOH
  echo 'start'
  #{graphite_manage} syncdb --noinput --settings=graphite.settings
  #{graphite_manage} createsuperuser --noinput --username=admin --email=paul@getchef.com --settings=graphite.settings
  EOH

  not_if { ::File.exist? '/var/lib/graphite/graphite.db' }
  notifies :run, 'execute[change_admin_pass]', :delayed
end

include_recipe "oc-graphite::_#{node['oc-graphite']['web']['server']}"
