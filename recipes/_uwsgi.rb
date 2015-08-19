#
# Cookbook Name:: oc-graphite
# Recipe:: _uwsgi
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

['uwsgi', 'uwsgi-plugin-python'].each do |pkg|
  package pkg
end

service 'uwsgi' do
  action :nothing
  supports :restart => true, :start => true, :stop => true, :reload => true
end

case node[:platform]
when 'amazon'
  packages = %w{ python27-devel python27-setuptools autoconf automake bison byacc crash cscope ctags diffstat doxygen elfutils flex gcc gcc-c++ gcc-gfortran gdb gettext git indent intltool kexec-tools latrace libtool ltrace patch patchutils rpm-build strace swig system-rpm-config systemtap systemtap-runtime texinfo perl-ExtUtils-Embed }

  packages.each do |pkg|
    package pkg do
      action :nothing
    end.run_action(:install)
  end

  bash 'install-uwsgi' do
    code 'pip install uwsgi -U --target="/usr/lib/python2.7/dist-packages"'
    not_if { system('pip show -q uwsgi') }
    notifies :restart, 'service[uwsgi]', :delayed
  end

  template '/etc/init.d/uwsgi' do
    source 'init.d/uwsgi.erb'
    owner 'root'
    group 'root'
    mode 0755
    notifies :restart, 'service[uwsgi]', :delayed
  end

  directory '/run/uwsgi' do
    owner '_graphite'
    group '_graphite'
    mode 0755
    notifies :restart, 'service[uwsgi]', :delayed
  end

  graphite_web_path = '/var/lib/graphite/conf'

  bash 'copy-uwsgi-carbon-conf' do
    code "cp #{graphite_web_path}/graphite.wsgi.example #{graphite_web_path}/graphite.wsgi"
    not_if { ::File.exist?("#{graphite_web_path}/graphite.wsgi") }
    notifies :restart, 'service[uwsgi]', :delayed
  end

  template '/etc/uwsgi.ini' do
    source 'uwsgi.ini.erb'
    owner 'uwsgi'
    group 'uwsgi'
    mode 0644
    notifies :restart, 'service[uwsgi]', :delayed
  end

  uwsgi_plugin_path = '/usr/lib64/uwsgi'

  template '/etc/uwsgi.d/graphite.ini' do
    source 'uwsgi-graphite.ini.erb'
    owner 'uwsgi'
    group 'uwsgi'
    mode 0644
    variables({ :graphite_web_path => graphite_web_path, :uwsgi_plugin_path => uwsgi_plugin_path })
    notifies :restart, 'service[uwsgi]', :delayed
  end

when 'ubuntu'
  graphite_web_path = '/usr/share/graphite-web'
  uwsgi_plugin_path = '/usr/lib/uwsgi/plugins'

  template '/etc/uwsgi/apps-available/graphite.ini' do
    source 'uwsgi-graphite.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables({ :graphite_web_path => graphite_web_path, :uwsgi_plugin_path => uwsgi_plugin_path })
    notifies :reload, 'service[uwsgi]', :delayed
  end

  link '/etc/uwsgi/apps-enabled/graphite.ini' do
    to '/etc/uwsgi/apps-available/graphite.ini'
    notifies :restart, 'service[uwsgi]', :delayed
  end
end

service 'uwsgi' do
  action [:enable, :start]
end
