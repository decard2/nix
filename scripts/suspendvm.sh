#!/bin/sh
detach() {
    virsh --connect qemu:///system detach-device win10 --file ~/vms/share.xml
}
suspend() {
    virsh --connect qemu:///system managedsave win10
}

set -e

detach || true
suspend || true
