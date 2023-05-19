{
  description = "A barebones NixOS installer script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, disko }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        disko_pkg = disko.packages.${system}.disko;
      in {
        packages = {
          installatore = pkgs.stdenv.mkDerivation {
            name = "installatore";
            src = ./.;
            buildInputs = [ pkgs.nushell pkgs.skim pkgs.bat disko_pkg ];
            phases = [ "installPhase" ];
            installPhase = ''
            # Copy Templates
            mkdir -p "$out/usr/share/installatore"
            cp -r "$src/templates/" "$out/usr/share/installatore"

            # Copy script
            mkdir -p "$out/bin"
            cp "$src/install.nu" "$out/bin/installatore"
            chmod +x "$out/bin/installatore"

            # Update paths to Nushell and Skim
            patchShebangs "$out/bin/installatore"
            substituteInPlace "$out/bin/installatore" \
              --replace 'sk_bin = "sk"' 'sk_bin = "${pkgs.skim}/bin/sk"' \
              --replace 'bat_bin = "bat"' 'bat_bin = "${pkgs.bat}/bin/bat"' \
              --replace 'disko_bin = "disko"' 'disko_bin = "${disko}/disko"' \
              --replace 'templates_path = "templates"' "templates_path = \"$out/usr/share/installatore/templates\""
            '';
          };
        };

        defaultPackage = self.packages.${system}.installatore;

        devShell = pkgs.stdenv.mkShell {
          buildInputs = [];
          shellHook = ''
          '';
        };
      }
    );
}
