#!/bin/bash
REGION=${REGION-"us-west-2"}
ZONE=${ZONE-"us-west-2a"}
SEC_GRP=${SEC_GRP}
SEC_KEY=${SEC_KEY}
KEYPATH=${KEYPATH}
INST_TYPE=${INST_TYPE-"t2.micro"}
VOL_SIZE=${VOL_SIZE-"8"}
SUBNET_ID=${SUBNET_ID}
AMI_ID=${AMI_ID-"ami-5189a661"}
_TMPFILE="/tmp/tmpfile$RANDOM" 
INPUTFLAG=0
#knife ec2 server create -I ami-5189a661  -r 'role[empty]' -Z us-west-2a  --security-group-ids sg-a23434351sds -S chef-test -i /Volumes/Projects/work/chef/chef-test.pem  -f t2.micro --region us-west-2 --ssh-user ubuntu

if [[ -z "$SEC_GRP" ]]
then
   echo "Please set the environment variable SEC_GRP";
   INPUTFLAG=1;
fi

if [[ -z "$SEC_KEY" ]]
then
   echo "Please set the environment variable SEC_KEY";
   INPUTFLAG=1;
fi

if [[ -z "$KEYPATH" ]]
then
   echo "Please set the environment variable KEYPATH";
   INPUTFLAG=1;
fi


if [[ $INPUTFLAG -eq 1 ]]
then
   exit;
fi
knife ec2 server create -I $AMI_ID  -r 'role[empty]' -Z $ZONE --ebs-size $VOL_SIZE --subnet $SUBNET_ID --security-group-ids  $SEC_GRP -S $SEC_KEY -i $KEYPATH  -f $INST_TYPE --region $REGION --ssh-user ubuntu --associate-public-ip | tee > $_TMPFILE
#knife ec2 server create -I $AMI_ID  -r 'role[empty]' -Z $ZONE --ebs-size $VOL_SIZE --groups $SEC_GRP -S $SEC_KEY -i $KEYPATH  -f $INST_TYPE --region $REGION --ssh-user ubuntu | tee > $_TMPFILE

PUB_IP=`grep "Public IP Address: " $_TMPFILE | head -1 | sed 's/Public IP Address: //'`
PRI_IP=`grep "Private IP Address: " $_TMPFILE | head -1 | sed 's/Private IP Address: //'`
INSTANCE_ID=`grep "Instance ID: " $_TMPFILE | head -1 | sed 's/Instance ID: //'`
echo "pub_ip" $PUB_IP
echo "priv_ip" $PRI_IP
echo "inst_id" $INSTANCE_ID
echo $_TMPFILE
