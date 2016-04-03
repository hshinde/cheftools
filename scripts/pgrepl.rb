# Create postgresql replication

# Create servers for master and slave
output = []
master = Hash.new;
slave = Hash.new;
count = 0;
datadir="/data"
def create_server(server)
  IO.popen("bash createserver.sh").each do |line|
    words=[]
    words=line.chomp.split
    server[words[0]]=words[1];
  end
end
create_server(master)
create_server(slave)


# Create Drive and mount point

# Set role attributes for PG replication
system("sed 's/MASTERIP/#{master['priv_ip']}/' /var/root/chef-repo/roles/pg_master.json | sed 's/SLAVEIP/#{slave['priv_ip']}/' > /tmp/pg_master.json")
system("sed 's/MASTERIP/#{master['priv_ip']}/' /var/root/chef-repo/roles/pg_slave.json | sed 's/SLAVEIP/#{slave['priv_ip']}/' > /tmp/pg_slave.json")
system("knife role from file /tmp/pg_master.json")
system("knife role from file /tmp/pg_slave.json")
system("knife node run_list add #{master['inst_id']} recipe[dbserver]")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\'")
system("knife node run_list add #{slave['inst_id']} recipe[dbserver]")
system("knife ssh \'name:#{slave['inst_id']}\' \'sudo chef-client\'")
system("knife node run_list add #{master['inst_id']} role[pg_master]")
system("knife ssh \'name:#{master['inst_id']}\' \'sudo chef-client\'")
system("knife node run_list add #{slave['inst_id']} role[pg_slave]")
system("knife ssh \'name:#{slave['inst_id']}\' \'sudo chef-client\'")

p "master" 
p  master
p "slave" 
p slave
# 
