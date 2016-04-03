#
# Cookbook Name:: dbserver
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#include 'aws::ebs_volume'

bash "apt-get-update" do
  code <<-EOH
	apt-get update
  EOH
  action :run
end


include_recipe "aws"


# get an unused device ID for the EBS volume
#devices = Dir.glob('/dev/sd?')
#devices = ['/dev/sda'] if devices.empty?
devices = Dir.glob('/dev/xvd?')
devices = ['/dev/xvda'] if devices.empty?
devid = devices.sort.last[-1,1].succ

# save the device used for data_volume on this node -- this volume will now always
# be attached to this device
#node.set_unless[:aws][:ebs_volume][:data_volume][:device] = "/dev/sd#{devid}"
node.set_unless[:aws][:ebs_volume][:data_volume][:device] = "/dev/xvd#{devid}"

device_id = node[:aws][:ebs_volume][:data_volume][:device]
node.default[:aws][:region]=ENV['REGION']
# Even though the volumes get the names sda, sdb etc, the same volumes inside ubuntu
# appear as xvda 

#device_id.gsub(/s/,'xv');
#device_id = "/dev/xvdb"
puts device_id
# create and attach the volume to the device determined above
aws_ebs_volume 'data_volume' do
  aws_access_key node[:dbserver][:aws_access_key]
  aws_secret_access_key node[:dbserver][:aws_secret_access_key]
  size node[:dbserver][:vol_size]
  device device_id
  action [:create, :attach]
end

# wait for the drive to attach, before making a filesystem
ruby_block "sleeping_data_volume" do
  block do
    timeout = 0
    until File.blockdev?(device_id) || timeout == 1000
      Chef::Log.debug("device #{device_id} not ready - sleeping 10s")
      timeout += 10
      sleep 10
    end
  end
end

mount_point = node[:dbserver][:mount_point] 
#'/data'

# create a filesystem
execute 'mkfs' do
  command "mkfs -t ext4 #{device_id}"
  # only if it's not mounted already
  not_if "grep -qs #{mount_point} /proc/mounts"
end

directory mount_point do
#  owner mount_point_owner
#  group mount_point_group
  mode '0777'
  action :create
  not_if "test -d #{mount_point}"
end


# now we can enable and mount it and we're done!
mount "#{mount_point}" do
  device device_id
  fstype 'ext4'
  options 'noatime,nobootwait'
  action [:enable, :mount]
end


# Create single server 
#include_recipe "postgresql::server"
#
## Stop the postgres server. Copy the data directory to mounted dir and start the server.
#
#bash 'change-postgres-datadir' do
#  code <<-EOH
#    mv "/var/lib/postgresql/#{node['postgresql']['version']}/main" #{node['postgresql']['config']['data_directory']}
#    service postgresql restart
#  EOH
#end

