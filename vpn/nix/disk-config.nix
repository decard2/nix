{ hostConfig, ... }:

let
  diskDevice = hostConfig.diskDevice or (if (hostConfig.isGCP or false) then "/dev/sda" else "/dev/vda");
  useEFI = hostConfig.useEFI or false;
in

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = diskDevice;
        content = {
          type = "gpt";
          partitions = {
            boot = if useEFI then {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            } else {
              size = "1M";
              type = "EF02"; # BIOS boot partition
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
