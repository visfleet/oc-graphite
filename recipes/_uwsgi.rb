#
# Cookbook Name:: oc-graphite
# Recipe:: _uwsgi
#
# Copyright (C) 2014, Chef Software, Inc <legal@getchef.com>

['uwsgi', 'uwsgi-plugin-python'].each do |pkg|
  package pkg
end

service 'uwsgi' do
  action [:enable, :start]
  supports :restart => true, :start => true, :stop => true, :reload => true
end

case node[:platform]
when 'amazon'
  graphite_web_path = '/var/lib/graphite'

  bash 'copy-uwsgi-carbon-conf' do
    code "cp #{graphite_web_path}/conf/graphite.wsgi.example #{graphite_web_path}/conf/graphite.wsgi"
    not_if { ::File.exist?("#{graphite_web_path}/conf/carbon.conf") }
  end

  template '/etc/uwsgi.d/graphite.ini' do
    source 'uwsgi-graphite.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables({ :graphite_web_path => graphite_web_path })

    notifies :reload, 'service[uwsgi]', :delayed
  end

when 'ubuntu'
  graphite_web_path = '/usr/share/graphite-web'

  template '/etc/uwsgi/apps-available/graphite.ini' do
    source 'uwsgi-graphite.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables({ :graphite_web_path => graphite_web_path })

    notifies :reload, 'service[uwsgi]', :delayed
  end

  link '/etc/uwsgi/apps-enabled/graphite.ini' do
    to '/etc/uwsgi/apps-available/graphite.ini'
  end
end
