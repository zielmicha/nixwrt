let
  armhf = rec {
    config = "arm-linux-gnueabihf";
    bigEndian = false;
    arch = "armhf";
    withTLS = true;
    libc = "glibc";
    platform = (import ../nixpkgs/lib/systems/platforms.nix).armv7l-hf-multiplatform;
    inherit (platform) gcc;
    openssl.system = "linux-generic32";
  };
in
import <nixpkgs> {
  crossSystem = armhf;
}
