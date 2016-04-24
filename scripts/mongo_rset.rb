# Create postgresql replication

# Create servers for master and slave
output = []
server1 = Hash.new;
server2 = Hash.new;
server3 = Hash.new;
count = 0;
clustername="pg_cluster"
chef_dir=ENV['CHEFDIR']
port = ENV['PORT'] || "27500";

require 'securerandom'
mongo_pass =  SecureRandom.hex
mongo_user = "admin"
vol_size = ENV['DATA_VOL_SIZE'] || 8;
mnt_path = ENV['MNT_PATH'] || '/data';
mnt_path = mnt_path.gsub('/','\/');

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

def keygen(chef_dir)
  key_file_content = ""; 
  IO.popen("openssl rand -base64 741").each do |line|
     if key_file_content.empty?
       key_file_content = line.chomp;
     else 
       key_file_content = key_file_content + line.chomp;
     end
  end
  system("sed 's|KEY_FILE_CONTENT|#{key_file_content}|' #{chef_dir}/roles/mongoset.json \
        > /tmp/mongoset.json")
end

keygen(chef_dir);

system("sed 's/AWS_ACCESS_KEY/#{aws_access_key}/' #{chef_dir}/roles/dbserver.json |\
        sed 's/AWS_SECRET_KEY/#{aws_secret_key}/' |\
        sed 's/VOLUME_SIZE/#{vol_size}/' |\
        sed 's/MOUNT_PATH/#{mnt_path}/' \
        > /tmp/dbserver.json")
system("knife role from file /tmp/dbserver.json")
system("knife role from file /tmp/mongoset.json")


ENV['REGION']=ENV['REGION1']||ENV['REGION'];
ENV['ZONE']=ENV['ZONE1']|| ENV['ZONE'];
ENV['SUBNET_ID']=ENV['SUBNET1']|| ENV['SUBNET_ID'];
create_server(server1)
#system("knife node run_list add #{server1['inst_id']} role[dbserver]")
system("knife node run_list add #{server1['inst_id']} recipe[server]")
system("knife ssh \'name:#{server1['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife ssh \'name:#{server1['inst_id']}\' \'sudo reboot\' -x ubuntu -i #{ENV['KEYPATH']}")

p "Created the first server."; 

# create second server
ENV['REGION']=ENV['REGION2']||ENV['REGION'];
ENV['ZONE']=ENV['ZONE2']|| ENV['ZONE'];
ENV['SUBNET_ID']=ENV['SUBNET2']|| ENV['SUBNET_ID'];
create_server(server2)
p "Created the second server.";

# add disk to the server
system("knife node run_list add #{server2['inst_id']} role[dbserver]")

# set kernel parameters
system("knife node run_list add #{server2['inst_id']} recipe[server]")
system("knife ssh \'name:#{server2['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")

# Kernel parameters need reboot to set them
system("knife ssh \'name:#{server2['inst_id']}\' \'sudo reboot\' -x ubuntu -i #{ENV['KEYPATH']}")


ENV['REGION']=ENV['REGION3']||ENV['REGION'];
ENV['ZONE']=ENV['ZONE3']|| ENV['ZONE'];
ENV['SUBNET_ID']=ENV['SUBNET3']|| ENV['SUBNET_ID'];
create_server(server3)
p "Created the third server.";

system("knife node run_list add #{server3['inst_id']} role[dbserver]")
system("knife node run_list add #{server3['inst_id']} recipe[server]")
system("knife ssh \'name:#{server3['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife ssh \'name:#{server3['inst_id']}\' \'sudo reboot\' -x ubuntu -i #{ENV['KEYPATH']}")


mongo_script = " 
rs.initiate(); 
db = db.getSiblingDB(\\\"admin\\\"); 
db.createUser( { user: \\\"#{mongo_user}\\\", pwd: \\\"#{mongo_pass}\\\", roles: [ { role: \\\"userAdminAnyDatabase\\\", db: \\\"admin\\\" } ] }) ";

mongo_rs_init = " rs.initiate(); ";

mongo_createuser = "
db = db.getSiblingDB(\\\"admin\\\"); 
db.createUser( { user: \\\"#{mongo_user}\\\", pwd: \\\"#{mongo_pass}\\\", roles: [ { role: \\\"userAdminAnyDatabase\\\", db: \\\"admin\\\" }, { role: \\\"root\\\", db: \\\"admin\\\" }  ] });
db.auth(\\\"#{mongo_user}\\\",\\\"#{mongo_pass}\\\");
rs.add(\\\"#{server2['priv_ip']}:#{port}\\\");
rs.add(\\\"#{server3['priv_ip']}:#{port}\\\");
";

mongo_addnodes = "
rs.add(\\\"#{server2['priv_ip']}:#{port}\\\");
rs.add(\\\"#{server3['priv_ip']}:#{port}\\\");
";


# Initialize master by installing necessary software.
system("knife node run_list add #{server1['inst_id']} role[mongoset]")
system("knife ssh \'name:#{server1['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
system("knife ssh \'name:#{server1['inst_id']}\' \'mongo localhost:#{port} --eval \"#{mongo_rs_init}\" \' -x ubuntu -i #{ENV['KEYPATH']}")
p "Installed MongoDB on server 1";

system("knife node run_list add #{server2['inst_id']} role[mongoset]")
system("knife ssh \'name:#{server2['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
p "Installed MongoDB on server 2";

system("knife node run_list add #{server3['inst_id']} role[mongoset]")
system("knife ssh \'name:#{server3['inst_id']}\' \'sudo chef-client\' -x ubuntu -i #{ENV['KEYPATH']}")
p "Installed MongoDB on server 3";
sleep(15)
system("knife ssh \'name:#{server1['inst_id']}\' \'mongo localhost:#{port} --eval \"#{mongo_createuser}\" \' -x ubuntu -i #{ENV['KEYPATH']}")
p "Server1" 
p server1
p "Password"
p mongo_pass
p "Server2" 
p server2
p "Server3" 
p server3

