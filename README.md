# Samba 4 + Alpine Linux Docker Image

This repository contains a basic Dockerfile for installing Samba 4
on Alpine Linux.

This is a solution for network filesharing. I use it on my self-built,
zfs-based NAS server and connect up OSX, Linux, and Windows clients.

I was previously running Netatalk for Apple AFP support, however
I've found that Samba works reasonably well for me and it appears
that [Apple may start prefering Samba over AFP](http://appleinsider.com/articles/13/06/11/apple-shifts-from-afp-file-sharing-to-smb2-in-os-x-109-mavericks).

## Create Samba Configuration

Create the `smb.conf` configuration file. The following is an example:

```
[global]
  workgroup = WORKGROUP
  server string = %h server (Samba, Alpine)
  security = user
  map to guest = Bad User
  encrypt passwords = yes
  load printers = no
  printing = bsd
  printcap name = /dev/null
  disable spoolss = yes
  disable netbios = yes
  server role = standalone
  server services = -dns, -nbt
  smb ports = 445
  name resolve order = hosts
  ;log level = 3

[Dozer]
  path = /dozer
  comment = ZFS
  browseable = yes
  writable = yes
  valid users = carol

[Shared]
  path = /share
  comment = Shared Folder
  browseable = yes
  read only = yes
  write list = carol
  guest ok = yes
```

For added security, you can control which interfaces Samba binds to and
which networks are allowed access. This is important if you're using
`--net=host` because Samba will bind to all interfaces by default and may
bind to an interface you hadn't intended. Add to the `[global]` section:

```
  hosts allow = 192.168.11.0/24 10.0.0.0/24
  hosts deny = 0.0.0.0/0
  interfaces = 192.168.11.0/24 10.0.0.0/24
  bind interfaces only = yes
```

I'm experimenting with the following settings (in the `[global]` section)
to add default permissions for windows clients, to enable extended features
for OSX clients, to enable recycle bins, and to be able to use ZFS's
posix-style ACLs.:

```
  create mask = 0664
  directory mask = 0775
  veto files = /.DS_Store/
  nt acl support = no
  inherit acls = yes
  ea support = yes
  vfs objects = catia fruit streams_xattr recycle
  acl_xattr:ignore system acls = yes
  recycle:repository = .recycle
  recycle:keeptree = yes
  recycle:versions = yes
```

## Running

Add/update the `-v` volumes below to match the shares defiend in your
`smb.conf` file and run:

```
docker run -dt \
  -v $PWD/smb.conf:/etc/samba/smb.conf \
  -v $PWD/dozer:/dozer \
  -v $PWD/share:/share \
  -p 445:445 \
  --name samba \
  --restart=always \
  b32147/samba
```

You can replace `-p 445:445` with `--net=host` above if you want to use your
host's networking stack instead of Docker's proxy but it's not necessary. You
can append additional arguments for `smbd` or append `--help` for a list of
options.

## Add Users

To add a user on startup, pass the username as an environmental argument:

```
-e SAMBA_USERNAME='a_username'
```

The password can either be set through Docker Secrets as SAMBA_PASSWORD or it
can also be passed as an environmental variable. The container will first look
for the secret file and if it does not exist, it will then check the environment.
```
-e SAMBA_PASSWORD='a_password'
```

Once the server is running, you can also add additional users using the following:

```
docker exec -it samba adduser -s /sbin/nologin -h /home/samba -H -D a_username
docker exec -it samba smbpasswd -a a_username
```

## Check Status

Check the logs for startup errors (adjust log level in `smb.conf` if needed),
then connect a client and check the status:

```
docker logs -f --tail=100 samba
docker exec -it samba smbstatus
```

## SSDP / ZeroConf Service Discovery

For auto-discovery on Linux and OSX machines, we can use the
multicast-based mDNS and DNS-SD protocls (also known as Bonjour) using
Avahi daemon.

The main use-case for this project is for a standalone, personal or small
workgroup file server with a majority of clients on OSX or Linux. I've
made a choice to not support legacy protocols, including NetBIOS, WINS,
and the old Samba port `139`. Some of the issues with NetBIOS include
excessive broadcast packets, lack of IPV6 support, and easy spoofing.

Because of this, it means:

* For Windows clients, your Samba server won't be shown under network
  browsing. Microsoft has been adding support for DNS-SD functionality
  recently, so it's possible they will eventually support finding Samba
  shares using mDNS and DNS-SD. In the meantime, you can still connect
  directly to the IP or hostname to use the shares.

* Samba can act as a domain controller or join an NT domain but that is not
  supported with this configuration. I may put together a separate
  project that supports NetBIOS/WINS and can either join or act as a domain
  controller.


