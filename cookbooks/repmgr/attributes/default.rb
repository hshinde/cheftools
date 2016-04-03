# encoding: UTF-8
# attributes for repmgr

default['build_essential']['compiletime'] = true
default['repmgr']['master_ip'] = '172.31.41.42'
default['repmgr']['slave_ip'] = ['172.31.33.64']

default['repmgr']['replication']['user'] = 'repmgr_usr'
default['repmgr']['replication']['password'] = 'useagudpasswd'
default['repmgr']['replication']['db']= 'repmgr_db'

# Config file
default['repmgr']['config']['cluster'] = 'clustername'
default['repmgr']['config']['node'] = 1
default['repmgr']['config']['node_name'] = 'node1'
default['repmgr']['config']['conninfo'] = "host=repmgr_node1 user=repmgr_usr dbname=repmgr_db"
default['repmgr']['config']['pg_bindir'] = "/usr/lib/postgresql/#{node['postgresql']['version']}/bin"
