#!/bin/bash

#change this accoirding to your need.
#KEYPATH="/Volumes/Projects/work/chef/chef-test.pem"

#USER=ubuntu
USER=postgres

if [ "$KEYPATH" = "" ]; then
  echo "ERROR: KEYPATH variable is undefined. Exiting...";
  exit;
fi
if [ "$USER" = "" ]; then
  echo "ERROR: USER variable is undefined. Exiting...";
  exit;
fi


# Get host list
count=0;
OUTDIR="out"
DIR=".pwlssh"

# Cleanup
rm -rf $OUTDIR/*

while read -r host ip 
do
  if [[ $host =~ '#' ]];
  then
    continue;
  fi 
  hostlist[$count]=$host;
  iplist[$count]=$ip;
#  echo ${hostlist[$count]}
  count=$(( $count + 1 ));
done < ./hostlist

if [ ! -d "$OUTDIR/$DIR" ]; then
  mkdir -p $OUTDIR/$DIR;
fi

# Generate keys and copy them back
for ((i=0;i<${#hostlist[@]};i++)); do
  echo ${hostlist[$i]}
  scp -oStrictHostKeyChecking=no -i $KEYPATH ./sshkey.sh ubuntu@${hostlist[$i]}:/tmp
  scp -oStrictHostKeyChecking=no -i $KEYPATH ./hostlist ubuntu@${hostlist[$i]}:/tmp
  ssh -oStrictHostKeyChecking=no -i $KEYPATH ubuntu@${hostlist[$i]} "sudo su - $USER -c 'bash /tmp/sshkey.sh' " 
  scp -oStrictHostKeyChecking=no -i $KEYPATH ubuntu@${hostlist[$i]}:/tmp/id_rsa.pub $OUTDIR/$DIR/${hostlist[$i]}.pub
  scp -oStrictHostKeyChecking=no -i $KEYPATH ubuntu@${hostlist[$i]}:~/.ssh/authorized_keys $OUTDIR/$DIR/${hostlist[$i]}.authorized_keys
  ssh -oStrictHostKeyChecking=no -i $KEYPATH ubuntu@${hostlist[$i]} "sudo su - $USER -c 'rm /tmp/id_rsa.pub' " 
done

for i in $OUTDIR/$DIR/*authorized_keys; do
  cat $i >> $OUTDIR/authorized_keys
done
# Copy in authorized_keys
for i in $OUTDIR/$DIR/*.pub; do
  cat $i >> $OUTDIR/authorized_keys
done


for ((i=0;i<${#hostlist[@]};i++)); do
  scp -oStrictHostKeyChecking=no -i $KEYPATH $OUTDIR/authorized_keys ubuntu@${hostlist[$i]}:/tmp
  ssh -oStrictHostKeyChecking=no -i $KEYPATH ubuntu@${hostlist[$i]} "sudo su - $USER -c 'cp /tmp/authorized_keys ~/.ssh/; ' "
done
