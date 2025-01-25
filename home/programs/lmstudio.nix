{
  lib,
  pkgs,
  ...
}:

let
  pname = "lmstudio";
  version = "0.3.8";
  rev = "4";

  src = pkgs.fetchurl {
    url = "https://installers.lmstudio.ai/linux/x64/${version}-${rev}/LM-Studio-${version}-${rev}-x64.AppImage";
    hash = "sha256-JnuEYU+vitBGS0WZdcleVW1DfZ+MonXz6U+ObUlsePM=";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
in
{
  home.packages = [
    (pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      meta = {
        description = "LM Studio is an easy to use desktop app for experimenting with local and open-source Large Language Models (LLMs)";
        homepage = "https://lmstudio.ai/";
        license = lib.licenses.unfree;
        mainProgram = "lmstudio";
        platforms = [
          "x86_64-linux"
          "aarch64-darwin"
        ];
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };

      extraPkgs = pkgs: [ pkgs.ocl-icd ];

      extraInstallCommands = ''
        mkdir -p $out/share/applications
        cp -r ${appimageContents}/usr/share/icons $out/share
        install -m 444 -D ${appimageContents}/lm-studio.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/lm-studio.desktop \
          --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=lmstudio'
      '';
    })
  ];
}
