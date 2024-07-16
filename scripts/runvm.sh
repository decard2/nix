#!/bin/sh
start() {
    virsh --connect qemu:///system start win10
}
resume() {
    virsh --connect qemu:///system resume win10
}
attach() {
    virsh --connect qemu:///system attach-device win10 --file ~/vms/share.xml    
}
connect() {    
    virt-viewer -r -f -d -a -c qemu:///system win10
}

set -e

start || true
resume || true
attach || true
connect
