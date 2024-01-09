#!/bin/sh
start()
{
    virsh --connect qemu:///system start win11
}
resume()
{
    virsh --connect qemu:///system resume win11
}
connect()
{
    virt-viewer -r -f -d -a -c qemu:///system win11
}

set -e

start || true
resume || true
connect