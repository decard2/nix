{
  description = "NixOS configuration for servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
    {
      nixosConfigurations = {
        frankfurt = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "frankfurt";
              serverIP = "37.221.125.150";
              gateway = "37.221.125.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
              containers = [ "remnanode" ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        bucharest = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "bucharest";
              serverIP = "45.67.34.30";
              gateway = "45.67.34.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [ "remnanode" ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        stockholm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "stockholm";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [ "remnanode" ];
              # Enable GCP features
              isGCP = true;
              # SSH keys for GCP OS Login key reuse
              sshKeys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDsuGJ6ijalQmg/9ocW6LTjAxwlEIGVrH+f/jRBWplLMYD7Ej6jsFO5nhhdTcMQE1RVvlcWWGK7bna9/3njzpg1o8ZXFLgMIXUm/1wZs11b8K3BmVBGjeTWldc+sGTNVwPaMqM3tfkRjD0Y3u77ppKtOA+TBcL+eqbBFxJ+qJEy3GiNG9fE/qBhzO4V6cfs13Z7HAtlxZXa8SP+z6Vs9uy3eQN5Lo6O8xyHqGv82NwYmEhsjwYnVQ8fRrIMyS3SSq/OXsaZHTRBHj3F5Hlg9R6xBNp9CqaPVwn/pzMcIw1Y4FdMD4ZiloOtOWr/Ft4ArH4yFywjdRJzkGC5oWpa6MlOCEV03dmvQ/sopJo/QXtk/jjfClG2u3fQp4uvt/bysaA5FTEZFmDAYIsvo284XQbcDdXRcOAMR1bvrxkX+sBWmUq9911bBpqsI8k2a6fJ/w3OdfsXJpm8UV6VnU0p8GdtofrVsKgqvAcRTV9OVwixOvo1WMKLq2vP09SLnOgkmDs= rolder"
              ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        panel = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "panel";
              serverIP = "91.207.183.149";
              gateway = "91.207.183.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
              containers = [ "remnapanel" ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };
      };
    };
}
