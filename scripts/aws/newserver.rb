require 'open-uri'
require 'aws-sdk'
require 'pp'
require 'optparse'
#require 'yaml'

aws_session_token = nil

# Create credentials object
#creds = Aws::Credentials.new(aws_access_key, aws_secret_access_key)

options = {}
opts = OptionParser.new do |parser|
  parser.banner = "Usage: example.rb [options]"

  parser.on('-r', '--region REGION', 'Region') { |v| options['region'] = v }
  parser.on('-z', '--zone ZONE', 'Availability Zone') { |v| options[:zone] = v }
  parser.on('-k', '--key KEYNAME', 'Key name') { |v| options[:keyname] = v }
  parser.on('-c', '--count COUNT', 'Number of instances') { |v| options[:count] = v }
  parser.on('-s', '--secgrp SEC_GRP1,SEC_GRP2', 'Security Group') { |v| options[:secgrp] = v.split(",") }
  parser.on('-t', '--inst_type INST_TYPE', 'Instance Type') { |v| options[:inst_type] = v }
  parser.on('-i', '--image_id IMAGEID', 'Image Id') { |v| options[:image_id] = v }
  #parser.on('-d', '--disk DISKSIZE', 'disksize') { |v| options[:disksize] = v }

end.parse!
#pp options

# Raise exception if the mandatory arguments are not specified.
begin 
  opts.parse!
  mandatory = [:keyname, :secgrp]
  missing = mandatory.select{ |param| options[param].nil? }        # the -t and -f switches
  unless missing.empty?                                            #
    puts "Missing options: #{missing.join(', ')}"                  #
    puts opts							   #
    exit                                                           #
  end                                                              #
rescue OptionParser::InvalidOption, OptionParser::MissingArgument      #
  puts $!.to_s                                                           # Friendly output when parsing fails
  puts opts	                                                         #
  exit                                                                   #
end          

# set defaults
options[:region] ||= 'us-west-2';
options[:zone] ||= 'us-west-2a';
options[:count] ||= '1';
options[:inst_type] ||= 't2.micro';
options[:image_id] ||= 'ami-5189a661';
#pp options

#  credentials: creds
Aws.config.update({
  region: options[:region]
})

#  credentials: creds
# Create AWS client object which will be used for EC operations 
ec2 = Aws::EC2::Client.new

resp = ec2.run_instances({
  image_id: options[:image_id],
  min_count: 1,
  max_count: options[:count],
  key_name: options[:keyname],
  security_groups: options[:secgrp],
  instance_type: options[:inst_type],
  placement: {
    availability_zone: options[:zone],
  }
});
#p resp
# Instance id list for waiting.
inst_id_list = []
resp.instances.select {|v| inst_id_list.push(v.instance_id) }
#p inst_id_list

inst = Aws::EC2::Instance.new({
  id: resp.instances[0].instance_id,
  client: ec2
})
#p inst.state['name']
inst.wait_until_running({
  instance_ids: inst_id_list
});

for i in 0...options[:count].to_i do 
  inst = Aws::EC2::Instance.new({
    id: resp.instances[i].instance_id,
    client: ec2
  })
  #pp inst
  inst.create_tags({
    tags: [ # required
      {
        key: 'Name',
        value: resp.instances[i].instance_id
      },
    ],
  })
end 
inst_id_list.select {|v| puts v }
