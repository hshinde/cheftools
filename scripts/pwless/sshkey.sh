#!/bin/bash
echo -e  'y\n'|ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
cp ~/.ssh/id_rsa.pub /tmp/
for i in `cat /tmp/hostlist | grep -v '#'`;
do
  ssh-keyscan  -H $i >>  ~/.ssh/known_hosts
done
