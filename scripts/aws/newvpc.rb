require 'open-uri'
require 'aws-sdk'
require 'pp'
require 'optparse'


options = {}
opts = OptionParser.new do |parser|
  parser.banner = "Usage: newvpc.rb [options]"
  parser.on('-c', '--cidr CIDR', 'CIDR block, IP range from ') { |v| options[:cidr] = v }
  parser.on('-r', '--region REGION', 'REGION') { |v| options[:region] = v }

end.parse!
#pp options

# Raise exception if the mandatory arguments are not specified.
begin 
  opts.parse!
  mandatory = [:cidr ]
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
#pp options

#  credentials: creds
Aws.config.update({
  region: options[:region]
})

#  credentials: creds
# Create AWS client object which will be used for EC operations 
ec2client = Aws::EC2::Client.new

vpcresp = ec2client.create_vpc({
  cidr_block: options[:cidr]
});

p vpcresp.vpc[:vpc_id]
