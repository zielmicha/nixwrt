with rec {
  _nixpkgs = import <nixpkgs> { };
  repo = _nixpkgs.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; rev = "849b5a5193be4c3e61af53e8db5bdb9d95b2074f"; sha256 = "1i1fhllx7k115zzjj0vf3qrmkp52icq2hb33qg5jig52vqk8ij6g"; };
};

with import repo {};

with rec {
  myglibc2_19 = pkgs.glibc.overrideDerivation (attrs: rec {
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

  myglibc2_23 = pkgs.glibc.overrideDerivation (attrs: rec {
    version = "2.23";
    name = "glibc-${version}";

    patches = [
      /* Have rpcgen(1) look for cpp(1) in $PATH.  */
      ./glibc2_23/rpcgen-path.patch

      /* Allow NixOS and Nix to handle the locale-archive. */
      ./glibc2_23/nix-locale-archive.patch

      /* Don't use /etc/ld.so.cache, for non-NixOS systems.  */
      ./glibc2_23/dont-use-system-ld-so-cache.patch

      /* Don't use /etc/ld.so.preload, but /etc/ld-nix.so.preload.  */
      ./glibc2_23/dont-use-system-ld-so-preload.patch

      /* Add blowfish password hashing support.  This is needed for
         compatibility with old NixOS installations (since NixOS used
         to default to blowfish). */
      ./glibc2_23/glibc-crypt-blowfish.patch

      /* The command "getconf CS_PATH" returns the default search path
         "/bin:/usr/bin", which is inappropriate on NixOS machines. This
         patch extends the search path by "/run/current-system/sw/bin". */
      ./glibc2_23/fix_path_attribute_in_getconf.patch

      ./glibc2_23/cve-2016-3075.patch
      ./glibc2_23/glob-simplify-interface.patch
      ./glibc2_23/cve-2016-1234.patch
      ./glibc2_23/cve-2016-3706.patch
    ];

    src = pkgs.fetchurl {
      url = "mirror://gnu/glibc/glibc-${version}.tar.xz";
      sha256 = "1s8krs3y2n6pzav7ic59dz41alqalphv7vww4138ag30wh0fpvwl";
    };
  });

  myglibc = if builtins.currentSystem == "armv7l-linux" then myglibc2_23 else myglibc2_19;
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
