require 'open-uri'
require 'aws-sdk'
require 'pp'
require 'optparse'


options = {}
opts = OptionParser.new do |parser|
  parser.banner = "Usage: newvpc.rb [options]"
  parser.on('-r', '--region REGION', 'REGION') { |v| options[:region] = v }
  parser.on('-n', '--name NAME', 'Name of load balancer') { |v| options[:name] = v }
  parser.on('-z', '--zone ZONE1,ZONE2,ZONE3', 'Availability Zone') { |v| options[:zone] = v.split(',') }
  parser.on('-l', '--lbprot LBPROTOCOL', 'Load balancer protocol') { |v| options[:lbprot] = v }
  parser.on('-i', '--iprot INSTPROTOCOL', 'Instance Protocol') { |v| options[:iprot] = v }
  parser.on('-p', '--lbport LBPORT', 'Load balancer port') { |v| options[:lbport] = v }
  parser.on('-t', '--iport INSTPORT', 'Instance port') { |v| options[:iport] = v }
  parser.on('-s', '--sg SecGRP1,SecGRP2,SecGRP3', 'Security Group') { |v| options[:secgrp] = v.split(',') }
end.parse!

# Raise exception if the mandatory arguments are not specified.
begin 
  opts.parse!
  mandatory = [:name, :zone]
  missing = mandatory.select{ |param| options[param].nil? }        # 
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
options[:lbprot] ||= 'http';
options[:iprot] ||= 'http';
options[:lbport] ||= '80';
options[:iport] ||= '80';
options[:zone] ||= ['us-west-2a'];

#  credentials: creds
Aws.config.update({
  region: options[:region]
})

#  credentials: creds
# Create AWS client object which will be used for EC operations 
elbclient = Aws::ElasticLoadBalancing::Client.new

resp = elbclient.create_load_balancer({
  load_balancer_name: options[:name],# required
  listeners: [ # required
    {
      protocol: options[:lbprot], # required
      load_balancer_port: options[:lbport].to_i, # required
      instance_protocol: options[:iprot],
      instance_port: options[:iport] # required
      #ssl_certificate_id: "SSLCertificateId",
    },
  ],
  
  availability_zones: options[:zone],
  #subnets: ["SubnetId"],
  #security_groups: ["SecurityGroupId"],
  scheme: "Internet-facing",
  tags: [
    {
      key: "name", # required
      value: options[:name]
    },
  ],
})

p resp
