#!/bin/sh
set -e

url='https://get.docker.io/'

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

sh_c='sh -c'
if [ "$(whoami 2>/dev/null || true)" != 'root' ]; then
    if command_exists sudo; then
        sh_c='sudo sh -c'
    elif command_exists su; then
        sh_c='su -c'
    else
        echo >&2 'Error: this installer needs the ability to run commands as root.'
        echo >&2 'We are unable to find either "sudo" or "su" available to make this happen.'
        exit 1
    fi
fi

curl=''
if command_exists curl; then
    curl='curl -sL'
elif command_exists wget; then
    curl='wget -qO-'
elif command_exists busybox && busybox --list-modules | grep -q wget; then
    curl='busybox wget -qO-'
fi

export DEBIAN_FRONTEND=noninteractive

did_apt_get_update=
apt_get_update() {
    if [ -z "$did_apt_get_update" ]; then
        ( set -x; $sh_c 'sleep 3; apt-get update' )
        did_apt_get_update=1
    fi
}

if ! grep -q aufs /proc/filesystems && ! $sh_c 'modprobe aufs'; then
    kern_extras="linux-image-extra-$(uname -r)"

    apt_get_update
    ( set -x; $sh_c 'sleep 3; apt-get install -y -q '"$kern_extras" ) || true

    if ! grep -q aufs /proc/filesystems && ! $sh_c 'modprobe aufs'; then
        echo >&2 'Warning: tried to install '"$kern_extras"' (for AUFS)'
        echo >&2 ' but we still have no AUFS.  Docker may not work. Proceeding anyways!'
        ( set -x; sleep 10 )
    fi
fi

if [ ! -e /usr/lib/apt/methods/https ]; then
    apt_get_update
    ( set -x; $sh_c 'sleep 3; apt-get install -y -q apt-transport-https' )
fi
if [ -z "$curl" ]; then
    apt_get_update
    ( set -x; $sh_c 'sleep 3; apt-get install -y -q curl' )
    curl='curl -sL'
fi
(
    set -x
    $sh_c "$curl ${url}gpg | apt-key add -"
    $sh_c "echo deb ${url}ubuntu docker main > /etc/apt/sources.list.d/docker.list"
    $sh_c 'sleep 3; apt-get update; apt-get install -y -q lxc-docker'
)
if command_exists docker && [ -e /var/run/docker.sock ]; then
    (
        set -x
        $sh_c 'docker run busybox echo "Docker has been successfully installed!"'
    ) || true
fi

docker run -d -p 80:80 hortont/rootserver
docker run -d -p 4281:80 hortont/hortontcom
docker run -d -p 4282:80 hortont/wmobitcom
