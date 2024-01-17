#!/bin/sh
start() {
    virsh --connect qemu:///system start win2k22
}
resume() {
    virsh --connect qemu:///system resume win2k22
}
attach() {
    virsh --connect qemu:///system attach-device win2k22 --file ~/vms/share.xml    
}
connect() {    
    virt-viewer -r -f -d -a -c qemu:///system win2k22
}

set -e

start || true
resume || true
attach || true
connect
