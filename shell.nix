{ pkgs }:
let
  arm-pkgs = pkgs.pkgsCross.armhf-embedded;
  buildPackages = arm-pkgs.buildPackages;
  newlib-nano = arm-pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "newlib";
    version = "4.3.0.20230120";

    src = pkgs.fetchurl {
      url = "ftp://sourceware.org/pub/newlib/newlib-${finalAttrs.version}.tar.gz";
      sha256 = "sha256-g6Yqma9Z4465sMWO0JLuJNcA//Q6IsA+QzlVET7zUVA=";
    };

    patches = [
      # https://bugs.gentoo.org/723756
      (pkgs.fetchpatch {
        name = "newlib-3.3.0-no-nano-cxx.patch";
        url = "https://gitweb.gentoo.org/repo/gentoo.git/plain/sys-libs/newlib/files/newlib-3.3.0-no-nano-cxx.patch?id=9ee5a1cd6f8da6d084b93b3dbd2e8022a147cfbf";
        sha256 = "sha256-S3mf7vwrzSMWZIGE+d61UDH+/SK/ao1hTPee1sElgco=";
      })
    ];

    depsBuildBuild = [
      buildPackages.stdenv.cc
      pkgs.texinfo
    ];

    preConfigure =
      ''
        export CC=cc
        substituteInPlace configure --replace 'noconfigdirs target-newlib target-libgloss' 'noconfigdirs'
        substituteInPlace configure --replace 'cross_only="target-libgloss target-newlib' 'cross_only="'
      '';

    configurePlatforms = [
      "build"
      "target"
    ];

    configureFlags =
      [
        "--with-newlib"
        "--host=${arm-pkgs.targetPlatform.config}"
        "--disable-newlib-fseek-optimization"
        "--disable-newlib-fvwrite-in-streamio"
        "--disable-newlib-supplied-syscalls"
        "--disable-newlib-unbuf-stream-opt"
        "--disable-newlib-wide-orient"
        "--disable-nls"
        "--enable-lite-exit"
        "--enable-newlib-global-atexit"
        "--enable-newlib-nano-formatted-io"
        "--enable-newlib-nano-malloc"
        "--enable-newlib-reent-check-verify"
        "--enable-newlib-reent-small"
        "--enable-newlib-retargetable-locking"
      ];
    enableParallelBuilding = true;
    dontDisableStatic = true;

    postInstall = ''
      mkdir -p $out${finalAttrs.passthru.incdir}/newlib-nano
      cp $out${finalAttrs.passthru.incdir}/newlib.h $out${finalAttrs.passthru.incdir}/newlib-nano/

      (
        cd $out${finalAttrs.passthru.libdir}

        for f in librdimon.a libc.a libg.a; do
          # Some libraries are only available for specific architectures.
          # For example, librdimon.a is only available on ARM.
          echo $f
          echo "=========================================================="
          [ -f "$f" ] && cp "$f" "''${f%%\.a}_nano.a"
        done
      )
    ''
    + ''[ "$(find $out -type f | wc -l)" -gt 0 ] || (echo '$out is empty' 1>&2 && exit 1)'';

    passthru = {
      incdir = "/${arm-pkgs.targetPlatform.config}/include";
      libdir = "/${arm-pkgs.targetPlatform.config}/lib";
    };

    meta = with pkgs.lib; {
      description = "C library intended for use on embedded systems";
      homepage = "https://sourceware.org/newlib/";
      license = licenses.gpl2Plus;
    };
  });

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    pkg-config
    gnumake
    openocd
    picotool
    python312Packages.pyserial
    buildPackages.gcc-arm-embedded
    buildPackages.binutils
    buildPackages.libcCross
    newlib-nano
  ];

  shellHook = ''
    export REACTOR_UC_PATH=../reactor-uc
    export OBJDUMP=${buildPackages.gcc-arm-embedded}/arm-none-eabi/bin/objdump
    export OBJCOPY=${buildPackages.gcc-arm-embedded}/arm-none-eabi/bin/objcopy
  '';
}
