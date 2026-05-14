{ pkgs, inputs, ... }:
let
  upstream = inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-stable;
in
{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "yandex-browser-stable-with-pipewire";
      paths = [ upstream ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/yandex-browser-stable \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.pipewire ]}

        for f in $out/share/applications/*.desktop; do
          if [ -L "$f" ]; then
            target=$(readlink -f "$f")
            rm "$f"
            sed -e "s|Exec=/nix/store/[^/]*/bin/yandex-browser-stable|Exec=$out/bin/yandex-browser-stable|g" \
                "$target" > "$f"
          fi
        done
      '';
    })
  ];
}
