require 'open-uri'
require 'aws-sdk'
require 'pp'
require 'optparse'
#require 'yaml'
#_ 
#
ec2 = Aws::EC2::Client.new 

root_device_type = "ebs"
ami_owner = '099720109477'
ami_name = "*ubuntu/images/#{root_device_type}/ubuntu-precise-12.04*"  # hardcoded to ubuntu 12.04. You can apply your own criteria here.


resp = ec2.describe_images({
  owners: ["099720109477"],
  filters: [
    {
      name: "launch.block-device-mapping.volume-type",
      values: ["gp2"],
    },
    {
      name: "architecture",
      values: ["x86_64"],
    },
    {
      name: "name",
      values: ["*ubuntu-trusty-14.04*"],
    },
    {
      name: "root-device-type",
      values: ["ebs"]
   }
  ],
});
max="0";
image_id="";
t="";
resp.images.select {|v| 
   if (max < v.creation_date) then
     max = v.creation_date;
     image_id = v.image_id; 
     t = v;
   end

}
p image_id;
