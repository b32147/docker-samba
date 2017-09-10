#!/bin/sh

# Set where the password file would exist.
PWD_FILE=/run/secrets/SAMBA_PASSWORD

# Check for a passed username.
if [ "$SAMBA_USERNAME" ]; then
  echo "Creating user $SAMBA_USERNAME..."
  
  # Add user.
  adduser -s /sbin/nologin -h /home/samba -H -D $SAMBA_USERNAME

  # Check for secrets.
  if [ -f "$PWD_FILE" ]; then
    echo "Reading $SAMBA_USERNAME's password from secrets..."
    
    # Add it to the user.
    printf "%s\n%s\n" "$(cat $PWD_FILE)" "$(cat $PWD_FILE)" | smbpasswd -sa $SAMBA_USERNAME
    
  # Check for the password as an environmental variable.  
  elif [[ -n "${SAMBA_PASSWORD}" ]]; then
    echo "Reading $SAMBA_USERNAME's password from env..."
    
    # Add it to the user.
    printf "%s\n%s\n" "$SAMBA_PASSWORD" "$SAMBA_PASSWORD" | smbpasswd -sa $SAMBA_USERNAME
  else
    echo "No password has been passed, not adding a password to the created user..."
  fi
else
  echo "No username has been passed, no user will be created..."
fi


# Run samba.
smbd --foreground --log-stdout
