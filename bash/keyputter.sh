#!/bin/bash

# Installs the current user's DSA key on all servers listed in the heredoc. 
# If the key requires a passphrase, be sure to set up ssh-agent as well.
# A key can be generated with: 
# 	ssh-keygen -t dsa -f ~/.ssh/id_dsa -C "user@server.com"

while read HOST
do
	echo "Installing on ${HOST}..."
	cat ~/.ssh/id_dsa.pub | ssh root@${HOST} 'test ! -d "/root/.ssh" && mkdir -p /root/.ssh; cat - >> ~/.ssh/authorized_keys'
done <<EOF
server.com
