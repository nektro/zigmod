{
  description = "A package manager for the Zig programming language.";
  inputs = {
    # zicross.url = github:flyx/Zicross;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    zig.url     = github:mitchellh/zig-overlay;
    utils.url   = github:numtide/flake-utils;
  };

  outputs = {self, nixpkgs, zig, utils, ...} @ inputs: with utils.lib;
    eachSystem allSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            zigpkgs = inputs.zig.packages.${prev.system};
          })
        ];
      };

      # Our supported systems are the same supported systems as the Zig binaries
      systems = builtins.attrNames inputs.zig.packages;

      pname = "zigmod";
      version = "0.1.0";

      zigVersion = "master";
      z = pkgs.zigpkgs.${zigVersion};

      zigmod = pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = ./.;
        nativeBuildInputs = with pkgs; [
          git
          mercurial
          wget
          unzip
          gnutar
          z
          pkg-config
        ];
        buildInputs = with pkgs; [ ];
        dontConfigure = true;
        preBuild = ''
          export HOME=$TMPDIR
        '';

        installPhase = ''
          runHook preInstall
          zig build --prefix $out install
          runHook postInstall
        '';

        installFlags = ["DESTDIR=$(out)"];

        meta = with pkgs.lib; {
          description = "A package manager for the Zig programming language.";
          license = licenses.mit;
          platforms = platforms.linux;
          maintainers = with maintainers; [ jakeisnt ];
        };
      };

    in rec {
      packages = {
        zigmod = zigmod;
        default = zigmod;
      };

      defaultPackage = zigmod;

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zigpkgs.master
        ];

        buildInputs = [
          git
          mercurial
          wget
          unzip
          gnutar
        ];
      };

      devShell = self.devShells.${system}.default;    });
}
