{ pkgs, ... }:
{
  systemd.services.libvirt-win11 = {
    description = "Windows 11 VM configuration";
    requires = [
      "libvirtd.service"
      "libvirtd-default-network.service"
    ];
    after = [
      "libvirtd.service"
      "libvirtd-default-network.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.libvirt ];
    script = ''
      if ! virsh list --all | grep -q "win11"; then
        virsh define ${pkgs.writeText "win11.xml" ''
          <domain type='kvm'>
            <name>win11</name>
            <uuid>269554e0-719c-4669-b628-604bb734d563</uuid>
            <metadata>
              <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
                <libosinfo:os id="http://microsoft.com/win/11"/>
              </libosinfo:libosinfo>
            </metadata>
            <memory unit='KiB'>8388608</memory>
            <currentMemory unit='KiB'>8388608</currentMemory>
            <memoryBacking>
              <source type="memfd"/>
              <access mode="shared"/>
            </memoryBacking>
            <vcpu placement='static'>6</vcpu>
            <os>
              <type arch='x86_64' machine='pc-q35-9.1'>hvm</type>
              <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
              <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/win11_VARS.fd</nvram>
              <boot dev='hd'/>
            </os>
            <features>
              <acpi/>
              <apic/>
              <hyperv mode='custom'>
                <relaxed state='on'/>
                <vapic state='on'/>
                <spinlocks state='on' retries='8191'/>
                <vpindex state='on'/>
                <runtime state='on'/>
                <synic state='on'/>
                <stimer state='on'/>
                <reset state='on'/>
                <vendor_id state='on' value='randomid'/>
                <frequencies state='on'/>
              </hyperv>
              <vmport state='off'/>
            </features>
            <cpu mode='host-passthrough' check='none' migratable='on'/>
            <clock offset='localtime'>
              <timer name='rtc' tickpolicy='catchup'/>
              <timer name='pit' tickpolicy='delay'/>
              <timer name='hpet' present='no'/>
              <timer name='hypervclock' present='yes'/>
            </clock>
            <on_poweroff>destroy</on_poweroff>
            <on_reboot>restart</on_reboot>
            <on_crash>destroy</on_crash>
            <pm>
              <suspend-to-mem enabled='no'/>
              <suspend-to-disk enabled='no'/>
            </pm>
            <devices>
              <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
              <disk type='file' device='disk'>
                <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
                <source file='/home/decard/vms/win11.qcow2'/>
                <target dev='vda' bus='virtio'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
              </disk>
              <controller type='usb' index='0' model='qemu-xhci' ports='15'>
                <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
              </controller>
              <controller type='pci' index='0' model='pcie-root'/>
              <controller type='pci' index='1' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='1' port='0x10'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
              </controller>
              <controller type='pci' index='2' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='2' port='0x11'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
              </controller>
              <controller type='pci' index='3' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='3' port='0x12'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
              </controller>
              <controller type='pci' index='4' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='4' port='0x13'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
              </controller>
              <controller type='pci' index='5' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='5' port='0x14'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
              </controller>
              <controller type='pci' index='6' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='6' port='0x15'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
              </controller>
              <controller type='pci' index='7' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='7' port='0x16'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
              </controller>
              <controller type='pci' index='8' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='8' port='0x17'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
              </controller>
              <controller type='pci' index='9' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='9' port='0x18'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>
              </controller>
              <controller type='pci' index='10' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='10' port='0x19'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>
              </controller>
              <controller type='pci' index='11' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='11' port='0x1a'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>
              </controller>
              <controller type='pci' index='12' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='12' port='0x1b'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>
              </controller>
              <controller type='pci' index='13' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='13' port='0x1c'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>
              </controller>
              <controller type='pci' index='14' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='14' port='0x1d'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>
              </controller>
              <controller type='sata' index='0'>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
              </controller>
              <controller type='virtio-serial' index='0'>
                <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
              </controller>
              <interface type='network'>
                <mac address='52:54:00:ef:15:65'/>
                <source network='default'/>
                <model type='virtio'/>
                <driver name='vhost' queues='8'/>
                <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
              </interface>
              <serial type='pty'>
                <target type='isa-serial' port='0'>
                  <model name='isa-serial'/>
                </target>
              </serial>
              <console type='pty'>
                <target type='serial' port='0'/>
              </console>
              <channel type='spicevmc'>
                <target type='virtio' name='com.redhat.spice.0'/>
                <address type='virtio-serial' controller='0' bus='0' port='1'/>
              </channel>
              <input type='tablet' bus='usb'>
                <address type='usb' bus='0' port='1'/>
              </input>
              <input type='mouse' bus='ps2'/>
              <input type='keyboard' bus='ps2'/>
              <tpm model='tpm-crb'>
                <backend type='emulator' version='2.0'/>
              </tpm>
              <graphics type='spice' autoport='yes'>
                <listen type='address'/>
                <image compression='off'/>
              </graphics>
              <sound model='ich9'>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
              </sound>
              <audio id='1' type='spice'/>
              <video>
                <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
              </video>
              <redirdev bus='usb' type='spicevmc'>
                <address type='usb' bus='0' port='2'/>
              </redirdev>
              <redirdev bus='usb' type='spicevmc'>
                <address type='usb' bus='0' port='3'/>
              </redirdev>
              <watchdog model='itco' action='reset'/>
              <memballoon model='virtio'>
                <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
              </memballoon>
              <filesystem type="mount" accessmode="passthrough">
                <driver type="virtiofs"/>
                <source dir="/home/decard"/>
                <target dir="home"/>
                <binary path="/run/current-system/sw/bin/virtiofsd"/>
                <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
              </filesystem>
            </devices>
          </domain>
        ''}
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };
}
