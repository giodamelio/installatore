{
  description = "A barebones NixOS installer script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs  } @ inputs: let
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
      packages.x86_64-linux = {
        installatore = pkgs.stdenv.mkDerivation {
          name = "installatore";
          src = ./install.nu;
          buildInputs = [ pkgs.nushell ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p "$out/bin"
            cp ${./install.nu} "$out/bin/installatore"
            chmod +x "$out/bin/installatore"
            patchShebangs "$out/bin/installatore"
          '';
        };
      };

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.installatore;

      devShell = pkgs.stdenv.mkShell {
        buildInputs = [];
        shellHook = ''
        '';
      };
    };
}
