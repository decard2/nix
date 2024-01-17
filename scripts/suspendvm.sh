#!/bin/sh
detach() {
    virsh --connect qemu:///system detach-device win2k22 --file ~/vms/share.xml
}
suspend() {
    virsh --connect qemu:///system managedsave win2k22
}

set -e

detach || true
suspend || true
