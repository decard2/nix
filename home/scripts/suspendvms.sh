#!/bin/sh
#
# 90virtualbox: scan for active virtual machines and pause them on host suspend

VBoxManage list runningvms | while read line; do VBoxManage controlvm "$(expr match "$line" '"\(.*\)"')" pause; done