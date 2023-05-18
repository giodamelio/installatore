{
  description = "A barebones NixOS installer script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          installatore = pkgs.stdenv.mkDerivation {
            name = "installatore";
            src = ./install.nu;
            buildInputs = [ pkgs.nushell pkgs.skim ];
            phases = [ "installPhase" ];
            installPhase = ''
            mkdir -p "$out/bin"
            cp ${./install.nu} "$out/bin/installatore"
            chmod +x "$out/bin/installatore"

            # Update paths to Nushell and Skim
            patchShebangs "$out/bin/installatore"
            substituteInPlace "$out/bin/installatore" --replace "sk --delimiter" "${pkgs.skim}/bin/sk --delimiter"
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
