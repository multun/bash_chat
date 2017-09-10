#!/bin/sh
cd "$(dirname "$0")"

wd="mktemp -d"
clear_wd () {
    rm -rf "$wd"
}
trap clear_wd EXIT
egrep "^[0-9]+$" <<< "$1" || exit 1

socat tcp-l:${1:-4242},reuseaddr,fork exec:"/bin/bash chat.sh ${wd}",pty,setsid,setpgid,stderr,ctty
