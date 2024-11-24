{
  disko.devices = {
    disk = {
      vda = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              name = "swap";
              size = "32G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                  };
                  "@home" = {
                    mountpoint = "/home";
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                  };
                  "@cache" = {
                    mountpoint = "/var/cache";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
