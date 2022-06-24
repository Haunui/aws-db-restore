#!/usr/bin/bash

DATABASE="webapp"

IP=$(cat instance_ip)

SSH_OPTS="-o StrictHostKeyChecking=no"
SSH_LOGIN="ubuntu@$IP"

BKP_SSH_LOGIN="bkp@192.168.0.9"

f=0

if [ -z "$(ssh $SSH_OPTS $SSH_LOGIN "sudo mysql -e \"show databases\"" | grep $DATABASE)" ]; then
  ssh $SSH_OPTS $SSH_LOGIN "sudo mysql -e 'create database $DATABASE'"
fi

while IFS= read -r line; do
  f=$(($f+1))
  echo "Download $line"
  rsync -e "ssh -o StrictHostKeyChecking=no" -az $BKP_SSH_LOGIN:/volume1/aws-bkp/$line .

  echo "Restore $line"
  scp $SSH_OPTS $line $SSH_LOGIN:~
  ssh $SSH_OPTS $SSH_LOGIN "sudo mysql $DATABASE < $line; rm -f $line"

  if [[ $line =~ ${DATABASE}.sql ]]; then
    echo "db backup found, exit"
    break
  fi

done < <(ssh -o StrictHostKeyChecking=no $BKP_SSH_LOGIN 'ls -t /volume1/aws-bkp')

echo "$f file restored"
