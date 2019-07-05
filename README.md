# SFTP

![Docker Automated build](https://img.shields.io/docker/automated/atmoz/sftp.svg) ![Docker Build Status](https://img.shields.io/docker/build/atmoz/sftp.svg) ![Docker Stars](https://img.shields.io/docker/stars/atmoz/sftp.svg) ![Docker Pulls](https://img.shields.io/docker/pulls/atmoz/sftp.svg)

![OpenSSH logo](https://raw.githubusercontent.com/atmoz/sftp/master/openssh.png "Powered by OpenSSH")

# Supported tags and respective `Dockerfile` links

- [`debian-stretch`, `debian`, `latest` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/master/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp.svg)](http://microbadger.com/images/atmoz/sftp "Get your own image badge on microbadger.com")
- [`debian-jessie` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/debian-jessie/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp:debian-jessie.svg)](http://microbadger.com/images/atmoz/sftp:debian-jessie "Get your own image badge on microbadger.com")
- [`alpine-3.7`, `alpine` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/alpine/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp:alpine-3.7.svg)](http://microbadger.com/images/atmoz/sftp:alpine-3.7 "Get your own image badge on microbadger.com")
- [`alpine-3.6` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/alpine-3.6/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp:alpine-3.6.svg)](http://microbadger.com/images/atmoz/sftp:alpine-3.6 "Get your own image badge on microbadger.com")

# Securely share your files with S3 filesystem baked-in with s3fs_fuse

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH).
This is an automated build linked with the [debian](https://hub.docker.com/_/debian/) and [alpine](https://hub.docker.com/_/alpine/) repositories.

# Usage

- Define users in (1) command arguments, (2) `SFTP_USERS` environment variable
  or (3) in file mounted as `/etc/sftp/users.conf` (syntax:
  `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]] ...`, see below for examples)
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Add directory names at the end, if you want to create them and/or set user
    ownership. Perfect when you just want a fast way to upload something without
    mounting any directories, or you want to make sure a directory is owned by
    a user (chown -R).
- Mount volumes in user's home directory. Not supported with s3fs_fuse addition
  - The users are chrooted to their home directory, so you must mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**).
- s3fs is currently only supported with a single user-dir.
  Adding additional mounts for multiple users should be simple, but not in my original use-case.
  last-in wins currently

# Examples

## Simplest docker run example

```
docker run -e S3_BUCKET_NAME=yourbucket[:/OPTIONAL_SUBDIR] -e AWSACCESSKEYID=your_aws_access_key_id -e AWSSECRETACCESSKEY=your_aws_secret_key --security-opt apparmor:unconfined --cap-add mknod --cap-add sys_admin --device=/dev/fuse -p 21:22 -d chessracer/sftp-s3fs testuser:pass:::sync_to_s3

```
User "testuser" with password "pass" can login with sftp and upload files to a folder in that container at /home/testuser/sync_to_s3. Files uploaded this way are synced to S3 in the named S3_BUCKET_NAME.
The provided AWSACCESSKEYID must be associated with a role that has access permissions to the S3 bucket.

### Using Docker Compose:
Run the provided docker-compose.yml file, providing values in the environment for for AWSACCESSKEYID, AWSSECRETACCESSKEY, S3_BUCKET_NAME, USERNAME, and PASSWORD. eg:

```
AWSACCESSKEYID=your_aws_access_key_id AWSSECRETACCESSKEY=your_aws_secret_key S3_BUCKET_NAME=your_bucket_name USERNAME=testuser PASSWORD=pass docker-compose up -d
```

## Example Login: connect to a locally-running instance on the default docker IP:
```
sftp -P 21 testuser@172.17.0.1:sync_to_s3
sftp> put somefile
sftp> ls
somefile
```

## Store users in config - NOTE: Multiple users not yet supported for s3fs (last-in wins for s3fs mount)

```
docker run \
    -v /host/users.conf:/etc/sftp/users.conf:ro \
    -v mySftpVolume:/home \
    -p 2222:22 -d atmoz/sftp
```

/host/users.conf:

```
foo:123:1001:100
bar:abc:1002:100
baz:xyz:1003:100
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d atmoz/sftp \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e:1001'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Logging in with SSH keys

Mount public keys in the user's `.ssh/keys/` directory. All keys are automatically appended to `.ssh/authorized_keys` (you can't mount this file directly, because OpenSSH requires limited file permissions). In this example, we do not provide any password, so the user `foo` can only login with his SSH key.

```
docker run \
    -v /host/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v /host/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d atmoz/sftp \
    foo::1001
```

## Providing your own SSH host key (recommended)

This container will generate new SSH host keys at first run. To avoid that your users get a MITM warning when you recreate your container (and the host keys changes), you can mount your own host keys.

```
docker run \
    -v /host/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
    -v /host/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d atmoz/sftp \
    foo::1001
```

Tip: you can generate your keys with these commands:

```
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
```

## Execute custom scripts or applications

Put your programs in `/etc/sftp.d/` and it will automatically run when the container starts.
See next section for an example.

## Bindmount dirs from another location

If you are using `--volumes-from` or just want to make a custom directory available in user's home directory, you can add a script to `/etc/sftp.d/` that bindmounts after container starts.

```
#!/bin/bash
# File mounted as: /etc/sftp.d/bindmount.sh
# Just an example (make your own)

function bindmount() {
    if [ -d "$1" ]; then
        mkdir -p "$2"
    fi
    mount --bind $3 "$1" "$2"
}

# Remember permissions, you may have to fix them:
# chown -R :users /data/common

bindmount /data/admin-tools /home/admin/tools
bindmount /data/common /home/dave/common
bindmount /data/common /home/peter/common
bindmount /data/docs /home/peter/docs --read-only
```

**NOTE:** Using `mount` requires that your container runs with the `CAP_SYS_ADMIN` capability turned on. [See this answer for more information](https://github.com/atmoz/sftp/issues/60#issuecomment-332909232).

# What's the difference between Debian and Alpine?

The biggest differences are in size and OpenSSH version. [Alpine](https://hub.docker.com/_/alpine/) is 10 times smaller than [Debian](https://hub.docker.com/_/debian/). OpenSSH version can also differ, as it's two different teams maintaining the packages. Debian is generally considered more stable and only bugfixes and security fixes are added after each Debian release (about 2 years). Alpine has a faster release cycle (about 6 months) and therefore newer versions of OpenSSH. As I'm writing this, Debian has version 7.4 while Alpine has version 7.5. Recommended reading: [Comparing Debian vs Alpine for container & Docker apps](https://www.turnkeylinux.org/blog/alpine-vs-debian)

# What version of OpenSSH do I get?

It depends on which linux distro and version you choose (see available images at the top). You can see what version you get by checking the distro's packages online. I have provided direct links below for easy access.

- [List of `openssh` packages on Alpine releases](https://pkgs.alpinelinux.org/packages?name=openssh&branch=&repo=main&arch=x86_64)
- [List of `openssh-server` packages on Debian releases](https://packages.debian.org/search?keywords=openssh-server&searchon=names&exact=1&suite=all&section=main)

**Note:** The time when this image was last built can delay the availability of an OpenSSH release. Since this is an automated build linked with [debian](https://hub.docker.com/_/debian/) and [alpine](https://hub.docker.com/_/alpine/) repos, the build will depend on how often they push changes (out of my control).  Typically this can take 1-5 days, but it can also take longer. You can of course make this more predictable by cloning this repo and run your own build manually.
