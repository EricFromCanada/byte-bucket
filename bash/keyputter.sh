#!/bin/bash

# Installs the current user's RSA key on all servers listed in the heredoc. 
# The first argument will be used as the username, defaulting to root if none provided.
# If the key requires a passphrase, be sure to set up ssh-agent as well.
# A key can be generated with: 
# 	ssh-keygen -t rsa -f ~/.ssh/id_rsa -C "user@server.com"

USER=${1:-root}

while read HOST
do
	echo "Installing on ${HOST}..."
	cat ~/.ssh/id_rsa.pub | ssh ${USER}@${HOST} 'test ! -d "~/.ssh" && mkdir -p ~/.ssh; cat - >> ~/.ssh/authorized_keys; type restorecon >/dev/null 2>&1 && restorecon -R ~/.ssh'
done <<EOF
server.com
