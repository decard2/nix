{ hostConfig, ... }:

let
  # Select disk device based on cloud provider
  diskDevice = if (hostConfig.isGCP or false) then "/dev/sda" else "/dev/vda";
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
            boot = {
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

  # Let disko handle bootloader configuration automatically
}
