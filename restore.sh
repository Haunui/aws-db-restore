#!/usr/bin/bash

DATABASE="webapp"

BKP_SSH_LOGIN="bkp@192.168.0.9"

f=0

if ! ssh -o StrictHostKeyChecking=no $BKP_SSH_LOGIN 'cat /volume1/aws-bkp/instance_ip' < /dev/null > instance_ip; then
  echo "No instance found"
  echo "Nothing to do."
  exit 0
fi

IP=$(cat instance_ip)

SSH_OPTS="-o StrictHostKeyChecking=no"
SSH_LOGIN="ubuntu@$IP"

bkp_files=

if [ -z "$(ssh $SSH_OPTS $SSH_LOGIN "sudo mysql -e \"show databases\"" | grep $DATABASE)" ]; then
  echo "Create database $DATABASE"
  ssh $SSH_OPTS $SSH_LOGIN "sudo mysql -e 'create database $DATABASE'"
  ssh $SSH_OPTS $SSH_LOGIN "sudo mysql -e 'show databases'"
fi

while IFS= read -r line; do
  f=$(($f+1))

  bkp_files="$bkp_files$line,"

  if [[ $line =~ ${DATABASE}.sql ]]; then
    echo "db backup found, stop ls"
    break
  fi

done < <(ssh -o StrictHostKeyChecking=no $BKP_SSH_LOGIN 'ls -t /volume1/aws-bkp | grep -v instance_ip')

if [ $f -gt 0 ]; then
  f=0
  while IFS= read -r line; do
    f=$(($f+1))

    echo "Download $line"
    rsync -e "ssh -o StrictHostKeyChecking=no" -az $BKP_SSH_LOGIN:/volume1/aws-bkp/$line .

    echo "Restore $line"
    scp $SSH_OPTS $line $SSH_LOGIN:~ < /dev/null
    ssh $SSH_OPTS $SSH_LOGIN "sudo mysql $DATABASE < $line; rm -f $line" < /dev/null

  done < <(echo "${bkp_files::-1}" | tr ',' '\n' | tac)
fi

echo "$f files restored"
