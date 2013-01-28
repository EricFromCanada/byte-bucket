#!/bin/bash

cp /dev/null user.htdigest
for i in $(cat /svn/repos/reponame/conf/passwd | cut -d '#' -f 1 | awk '/= / { print $1":trac:"$3 }')
do 
	echo -e $(echo $i | cut -d ":" -f 1-2):$(echo -n $i | md5sum | cut -d " " -f 1) >> user.htdigest
done
