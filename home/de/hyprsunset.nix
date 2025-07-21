{ pkgs, ... }:

let
  hyprsunset-030 = pkgs.hyprsunset.overrideAttrs (oldAttrs: {
    version = "0.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprsunset";
      tag = "v0.3.0";
      hash = "sha256-Cp5kHNfWFFyJpA5eRxZh/7fJcHU1uM2tBehQyeyKEUA=";
    };

    buildInputs = oldAttrs.buildInputs ++ [ pkgs.hyprlang ];

    meta = oldAttrs.meta // {
      description = "Application to enable a blue-light filter on Hyprland (version 0.3.0)";
    };
  });
in
{
  home.packages = [ hyprsunset-030 ];
}
