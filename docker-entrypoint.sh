#!/bin/sh

# Add user.
adduser -s /sbin/nologin -h /home/samba -H -D $USERNAME
printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | smbpasswd -sa $USERNAME

# Run samba.
smbd --foreground --log-stdout
