with import <nixpkgs> {};

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    git
    mercurial
    wget unzip gnutar
    pkg-config zlib
  ];

  hardeningDisable = [ "all" ];
}
