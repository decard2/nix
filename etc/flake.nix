{
  inputs.main.url = "path:/home/decard/nix";
  outputs = { main }: {
    nixosConfigurations.emerald = main.nixosConfigurations.emerald;
  };
}
