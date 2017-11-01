with rec {
  _nixpkgs = import <nixpkgs> { };
  repo = _nixpkgs.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; rev = "849b5a5193be4c3e61af53e8db5bdb9d95b2074f"; sha256 = "1i1fhllx7k115zzjj0vf3qrmkp52icq2hb33qg5jig52vqk8ij6g"; };
};

with import repo {};

with rec {
  myglibc = pkgs.glibc.overrideDerivation (attrs: rec {
    version = "2.19";
    name = "glibc-${version}";

    patches = [
      ./glibc/rpcgen-path.patch

      /* Allow NixOS and Nix to handle the locale-archive. */
      ./glibc/nix-locale-archive.patch

      /* Don't use /etc/ld.so.cache, for non-NixOS systems.  */
      ./glibc/dont-use-system-ld-so-cache.patch

      /* Don't use /etc/ld.so.preload, but /etc/ld-nix.so.preload.  */
      ./glibc/dont-use-system-ld-so-preload.patch

      /* Add blowfish password hashing support.  This is needed for
      compatibility with old NixOS installations (since NixOS used
      to default to blowfish). */
      ./glibc/glibc-crypt-blowfish.patch

      /* The command "getconf CS_PATH" returns the default search path
      "/bin:/usr/bin", which is inappropriate on NixOS machines. This
      patch extends the search path by "/run/current-system/sw/bin". */
      ./glibc/fix_path_attribute_in_getconf.patch

      ./glibc/fix-math.patch

      ./glibc/cve-2014-0475.patch
      ./glibc/cve-2014-5119.patch

      /* Remove references to the compilation date.  */
      ./glibc/glibc-remove-date-from-compilation-banner.patch
    ];

    src = pkgs.fetchurl {
      url = "mirror://gnu/glibc/glibc-${version}.tar.xz";
      sha256 = "18m2dssd6ja5arxmdxinc90xvpqcsnqjfwmjl2as07j0i3srff9d";
    };
  });
};

import pkgs.path {
  overlays = [ (self: super: {
    newGlibcPkgs = pkgs;

    portable = callPackage ./makePortable.nix {};

    glibc = myglibc;

    gnutls = super.gnutls.overrideDerivation (attrs: {doCheck = false;});

    # 1. coreutils tests are flaky, disable them
    # 2. only do this if these are not bootstrap coreutils
    coreutils = if builtins.hasAttr "overrideDerivation" super.coreutils then
      super.coreutils.overrideDerivation (attrs: {doCheck = false;})
      else super.coreutils;
  } ) ];
}
