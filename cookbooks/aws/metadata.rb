name 'aws'
maintainer 'Chef Software, Inc'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'LWRPs for managing AWS resources'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.7.2'
recipe 'aws', 'Installs the right_aws gem during compile time'
source_url 'https://github.com/chef-cookbooks/aws' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/aws/issues' if respond_to?(:issues_url)
