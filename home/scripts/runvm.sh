#!/bin/sh
start()
{
    virsh --connect qemu:///system start win10
}
resume()
{
    virsh --connect qemu:///system resume win10
}
connect()
{
    virt-viewer -r -f -d -a -c qemu:///system win10
}

set -e

start || true
resume || true
connect