# Create postgresql replication

# Create servers for master and slave
output = []
master = Hash.new;
slave = Hash.new;
count = 0;
clustername="pg_cluster"
chef_dir=ENV['CHEFDIR']
vol_size=ENV['VOL_SIZE'] || 8;
mnt_path=ENV['MNT_PATH'] || '/data';
mnt_path=mnt_path.gsub('/','\/');

if ! ENV['AWS_ACCESS_KEY'] || ! ENV['AWS_SECRET_KEY']
   p "Set the AWS_ACCESS_KEY and AWS_SECRET_KEY variable";
   exit
end

aws_access_key=ENV['AWS_ACCESS_KEY'];
aws_secret_key=ENV['AWS_SECRET_KEY'];


def create_server(server)
  IO.popen("bash createserver.sh").each do |line|
    words=[]
    words=line.chomp.split
    server[words[0]]=words[1];
    p words
  end
end

create_server(master)
create_server(slave)
system("echo #{master['pub_ip']} #{master['priv_ip']} \
             '\n'#{slave['pub_ip']} #{slave['priv_ip']} > pwless/hostlist");

system("sed 's/AWS_ACCESS_KEY/#{aws_access_key}/' #{chef_dir}/roles/dbserver.json |\
        sed 's/AWS_SECRET_KEY/#{aws_secret_key}/' |\
        sed 's/VOLUME_SIZE/#{vol_size}/' |\
        sed 's/MOUNT_PATH/#{mnt_path}/' \
        > /tmp/dbserver.json")
system("knife role from file /tmp/dbserver.json")


# Create Drive and mount point
nodenum=1
# Set role attributes for PG replication
system("sed 's/MASTERIP/#{master['priv_ip']}/' #{chef_dir}/roles/repmgr_master.json |\
        sed 's/SLAVEIP/#{slave['priv_ip']}/' |\
        sed 's/CLUSTERNAME/#{clustername}/' |\
        sed 's/NODENUM/#{nodenum}/' |\
        sed 's/NODENAME/node#{nodenum}/' \
        > /tmp/repmgr_master.json")
system("knife role from file /tmp/repmgr_master.json")

nodenum = nodenum + 1;

system("sed 's/MASTERIP/#{master['priv_ip']}/' #{chef_dir}/roles/repmgr_slave.json |\
        sed 's/SLAVEIP/#{slave['priv_ip']}/' |\
        sed 's/CLUSTERNAME/#{clustername}/' |\
        sed 's/NODENUM/#{nodenum}/' |\
        sed 's/NODENAME/node#{nodenum}/' \
        > /tmp/repmgr_slave.json")
system("knife role from file /tmp/repmgr_slave.json")

# Initialize master by installing necessary software.

system("knife node run_list add #{master['inst_id']} role[dbserver]")
system("knife node run_list add #{slave['inst_id']}  role[dbserver]")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife ssh \'name:#{slave['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
exit

system("knife node run_list add #{master['inst_id']} role[repmgr_master]")
#system("echo knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']} ")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")

system("knife node run_list add #{slave['inst_id']} recipe[postgresql::server]")
system("knife ssh \'name:#{slave['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("cd pwless; bash pwless.sh ")
system("knife node run_list add #{master['inst_id']} recipe[postgresql::server_conf]")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo -u postgres repmgr -f /etc/repmgr/repmgr.conf --verbose master register\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife node run_list add #{slave['inst_id']} role[repmgr_slave]")
system("knife ssh \'name:#{slave['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
p "master" 
p  master
p "slave" 
p  slave

