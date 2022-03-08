with import <nixpkgs> {};

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    git
    mercurial
    wget unzip gnutar
  ];

  hardeningDisable = [ "all" ];
}
