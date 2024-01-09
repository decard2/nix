#!/bin/sh
start()
{
    virsh --connect qemu:///system start win2k22
}
resume()
{
    virsh --connect qemu:///system resume win2k22
}
connect()
{
    virt-viewer -r -f -d -a -c qemu:///system win2k22
}

set -e

start || true
resume || true
connect