#!/bin/sh

# Add user.
adduser -s /sbin/nologin -h /home/samba -H -D $USERNAME
printf '$PASSWORD\n$PASSWORD\n' | smbpasswd -sa $USERNAME

# Run samba.
smbd --foreground --log-stdout
