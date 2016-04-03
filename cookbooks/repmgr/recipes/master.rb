# encoding: UTF-8
#
# Cookbook Name:: repmgr
# Recipe:: repmgr_master
#
# Author:: Hemant Shinde
#
# Copyright 2016, Mobisoft Infotech
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# specific settings for master postgresql server

#require 'spec_helper'

# set SSL usage based on OS support (debian yes, Redhat no)
case node['platform_family']
when 'debian'
  node.set['repmgr']['host'] = 'hostssl'
else
  node.set['repmgr']['host'] = 'host'
end
# Create repmgr user and database 
node.default['postgresql']['pg_hba'] << {
  comment: '# authorize slave server',
  type: node['repmgr']['host'],
  db: 'replication',
  user: node['repmgr']['replication']['user'],
  addr: "#{node['repmgr']['master_ip']}/32",
  method: 'trust'
    #method: 'md5'
}
node.default['postgresql']['pg_hba'] << {
  comment: '# authorize slave server',
  type: node['repmgr']['host'],
  db: node['repmgr']['replication']['db'],
  user: node['repmgr']['replication']['user'],
  addr: "#{node['repmgr']['master_ip']}/32",
  method: 'trust'
    #method: 'md5'
}


# build array for use in pg_hba.conf file
node['repmgr']['slave_ip'].each do |slaveip|
  node.default['postgresql']['pg_hba'] << {
    comment: '# authorize slave server',
    type: node['repmgr']['host'],
    db: 'replication',
    user: node['repmgr']['replication']['user'],
    addr: "#{slaveip}/32",
    method: 'trust'
  }
end
node['repmgr']['slave_ip'].each do |slaveip|
  node.default['postgresql']['pg_hba'] << {
    comment: '# authorize slave server',
    type: node['repmgr']['host'],
    db: node['repmgr']['replication']['db'],
    user: node['repmgr']['replication']['user'],
    addr: "#{slaveip}/32",
    method: 'trust'
  }
end
# Install necessary packages
#
package 'make'
package 'git'
package 'libxslt-dev'
package 'libxml2-dev'
package 'libpam-dev'
package 'libedit-dev'
package "postgresql-server-dev-#{node['postgresql']['version']}"
include_recipe 'repmgr::default'

# ubuntu specific installation
execute 'install-repmgr' do
  cloned = %(repmgr --version | grep repmgr)
  command <<-EOH
    mkdir repmgr_src
    cd repmgr_src
    git clone https://github.com/2ndQuadrant/repmgr
    cd repmgr
    make USE_PGXS=1 deb
    cd ..
    dpkg -i postgresql-repmgr-*.deb
  EOH
  not_if cloned, user: 'root'
  user 'root'
  cwd '/tmp/'
  action :run 
end

node.set['postgresql']['config']['listen_addresses'] = '*'
node.set['postgresql']['config']['wal_level'] = 'hot_standby'
node.set['postgresql']['config']['hot_standby'] = 'on'
node.set['postgresql']['config']['max_wal_senders'] = 10
node.set['postgresql']['config']['checkpoint_segments'] = 8
node.set['postgresql']['config']['wal_keep_segments'] = 5000
node.set['postgresql']['config']['archive_mode'] = 'on'
node.set['postgresql']['config']['archive_command'] = 'cd .'


ruby_block "set_app_id" do
  block do
    run_context.node.set['postgresql']['config']['shared_preload_libraries'] = 'repmgr_funcs'
    run_context.include_recipe 'postgresql::server_conf'
  end
end


# adds replication user to database
execute 'set-replication-user' do
  role_exists = %(psql -c "SELECT rolname FROM pg_roles WHERE rolname='#{node['repmgr']['replication']['user']}'" | grep #{node['repmgr']['replication']['user']})
  command %Q(psql -c "CREATE USER #{node['repmgr']['replication']['user']} REPLICATION SUPERUSER LOGIN ENCRYPTED PASSWORD '#{node['repmgr']['replication']['password']}';")
  not_if role_exists,  user: 'postgres'
  user 'postgres'
  action :run
end
# Create database for repmgr
execute 'set-replication-db' do
  db_exists = %(psql -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | grep #{node['repmgr']['replication']['db']})
  command %Q(psql -c "CREATE DATABASE #{node['repmgr']['replication']['db']} OWNER #{node['repmgr']['replication']['user']} ;")
  not_if db_exists,  user: 'postgres'
  user 'postgres'
  action :run
end
# Create repmgr config file
#
directory '/etc/repmgr' do
  owner "postgres"
  group "postgres"
  recursive true
  recursive true
  action :create
end

template "/etc/repmgr/repmgr.conf" do
  source "repmgr.config.erb"
  mode "0644"
  cookbook "repmgr"
  action :create
end

tag('pg_master')
