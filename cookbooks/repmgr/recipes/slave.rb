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
#node.default['postgresql']['pg_hba'] << {
#  comment: '# authorize slave server',
#  type: node['repmgr']['host'],
#  db: 'replication',
#  user: node['repmgr']['replication']['user'],
#  addr: "#{node['repmgr']['master']}/32",
#  method: 'trust'
#    #method: 'md5'
#}
#node.default['postgresql']['pg_hba'] << {
#  comment: '# authorize slave server',
#  type: node['repmgr']['host'],
#  db: node['repmgr']['replication']['db'],
#  user: node['repmgr']['replication']['user'],
#  addr: "#{node['repmgr']['master']}/32",
#  method: 'trust'
#    #method: 'md5'
#}
#

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

# Stopping the server before restarting. 
service "postgresqlstop" do
  service_name node['postgresql']['server']['service_name']
  supports :status => true
  action [:stop]
end

data_dir=node['postgresql']['config']['data_directory'];
databkp=data_dir + ".bak" 
   # mv #{data_dir} #{databkp} 
execute 'set-repmgr' do
  command <<-EOH
    rm -rf /data/main/*;
    repmgr --force -D #{data_dir} -d #{node['repmgr']['replication']['db']} -U #{node['repmgr']['replication']['user']} --verbose standby clone #{node['repmgr']['master_ip']};
    cp #{data_dir}/pg_hba.conf #{node['postgresql']['dir']}/ ;
    cp #{data_dir}/postgresql.conf #{node['postgresql']['dir']}/;
    cp #{data_dir}/recovery.conf #{node['postgresql']['dir']}/;
  EOH
  user 'postgres'
  cwd '/tmp/'
  action :run 
end

# Stopping the server before restarting. 
service "postgresqlstart" do
  service_name node['postgresql']['server']['service_name']
  supports :status => true
  action [:restart]
end
execute 'set-repmgr' do
  command <<-EOH
    repmgr -f /etc/repmgr/repmgr.conf --verbose standby register;
  EOH
  user 'postgres'
  cwd '/tmp/'
  action :run 
end

tag('pg_slave')
