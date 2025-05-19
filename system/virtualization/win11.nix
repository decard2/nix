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
          <domain type="kvm">
            <name>win11</name>
            <uuid>1e24c975-f14e-46a0-ab4b-e20ccaaf5137</uuid>
            <metadata>
              <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
                <libosinfo:os id="http://microsoft.com/win/11"/>
              </libosinfo:libosinfo>
            </metadata>
            <memory>8388608</memory>
            <currentMemory>8388608</currentMemory>
            <memoryBacking>
              <source type="memfd"/>
              <access mode="shared"/>
            </memoryBacking>
            <vcpu placement='static'>8</vcpu>
            <os firmware="efi">
              <type arch="x86_64" machine="q35">hvm</type>
              <boot dev="hd"/>
            </os>
            <features>
              <acpi/>
              <apic/>
              <hyperv>
                <relaxed state="on"/>
                <vapic state="on"/>
                <spinlocks state="on" retries="8191"/>
                <vpindex state="on"/>
                <runtime state="on"/>
                <synic state="on"/>
                <stimer state="on"/>
                <frequencies state="on"/>
                <tlbflush state="on"/>
                <ipi state="on"/>
                <evmcs state="on"/>
                <avic state="on"/>
              </hyperv>
              <vmport state="off"/>
            </features>
            <cpu mode="host-passthrough" check="none" migratable="on">
              <topology sockets="1" dies="1" cores="4" threads="2"/>
              <cache mode="passthrough"/>
            </cpu>
            <clock offset="localtime">
              <timer name="rtc" tickpolicy="catchup"/>
              <timer name="pit" tickpolicy="delay"/>
              <timer name="hpet" present="no"/>
              <timer name="hypervclock" present="yes"/>
            </clock>
            <pm>
              <suspend-to-mem enabled="no"/>
              <suspend-to-disk enabled="no"/>
            </pm>
            <devices>
              <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
              <disk type="file" device="disk">
                <driver name="qemu" type="qcow2"/>
                <source file="/home/decard/vms/win11.qcow2"/>
                <target dev="vda" bus="virtio"/>
              </disk>
              <controller type="usb" model="qemu-xhci" ports="15"/>
              <controller type="pci" model="pcie-root"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <controller type="pci" model="pcie-root-port"/>
              <interface type="network">
                <source network="default"/>
                <mac address="52:54:00:56:2d:ba"/>
                <model type="virtio"/>
              </interface>
              <console type="pty"/>
              <channel type="spicevmc">
                <target type="virtio" name="com.redhat.spice.0"/>
              </channel>
              <input type="tablet" bus="usb"/>
              <tpm model="tpm-crb">
                <backend type="emulator"/>
              </tpm>
              <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
                <image compression="off"/>
              </graphics>
              <sound model="ich9"/>
              <video>
                <model type="qxl"/>
              </video>
              <redirdev bus="usb" type="spicevmc"/>
              <redirdev bus="usb" type="spicevmc"/>
              <filesystem type="mount">
                <source dir="/home/decard"/>
                <target dir="home"/>
                <driver type="virtiofs"/>
                <binary path="/run/current-system/sw/bin/virtiofsd"/>
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
