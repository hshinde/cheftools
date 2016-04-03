#!/bin/bash
REGION=${REGION-"us-west-2"}
ZONE=${ZONE-"us-west-2a"}
SEC_GRP=${SEC_GRP-"launch-wizard-1"}
SEC_KEY=${SEC_KEY-"chef-test"}
KEYPATH=${KEYPATH-"/Volumes/Projects/work/chef/chef-test.pem"}
INST_TYPE=${INST_TYPE-"t2.micro"}
AMI_ID=${AMI_ID-"ami-5189a661"}
_TMPFILE="/tmp/tmpfile$RANDOM" 
#knife ec2 server create -I ami-5189a661  -r 'role[empty]' -Z us-west-2a  --groups launch-wizard-1 -S chef-test -i /Volumes/Projects/work/chef/chef-test.pem  -f t2.micro --region us-west-2 --ssh-user ubuntu

knife ec2 server create -I $AMI_ID  -r 'role[empty]' -Z $ZONE  --groups $SEC_GRP -S $SEC_KEY -i $KEYPATH  -f $INST_TYPE --region $REGION --ssh-user ubuntu | tee > $_TMPFILE

PUB_IP=`grep "Public IP Address: " $_TMPFILE | head -1 | sed 's/Public IP Address: //'`
PRI_IP=`grep "Private IP Address: " $_TMPFILE | head -1 | sed 's/Private IP Address: //'`
INSTANCE_ID=`grep "Instance ID: " $_TMPFILE | head -1 | sed 's/Instance ID: //'`
echo "pub_ip" $PUB_IP
echo "priv_ip" $PRI_IP
echo "inst_id" $INSTANCE_ID
echo $_TMPFILE
