with import <nixpkgs> {};

rec {
  armpkgs = pkgs.forceSystem "x86_64-linux" "i386";
}
