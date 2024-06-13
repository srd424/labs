{
  lib,
  config,
}: let
  lib' = config.lib;
  types = config.lib.systems.types;

  setTypes = type: let
    assign = name: value:
      assert lib.errors.trace (type.check value) "${name} is not of type ${type.name}: ${lib.generators.pretty {} value}";
        lib.types.set name ({inherit name;} // value);
  in
    builtins.mapAttrs assign;

  matchAnyAttrs = patterns:
    if builtins.isList patterns
    then value: builtins.any (pattern: lib.attrs.match pattern value) patterns
    else lib.attrs.match patterns;
in {
  config = {
    lib.systems = {
      match = builtins.mapAttrs (lib.fp.const matchAnyAttrs) lib'.systems.patterns;

      types = {
        generic = {
          endian = lib.types.create {
            name = "Endian";
            description = "Endianness";
            merge = lib.options.merge.one;
          };

          cpu = lib.types.create {
            name = "Cpu";
            description = "Instruction set architecture name and information";
            merge = lib.options.merge.one;
            check = x:
              types.bits.check x.bits
              && (
                if 8 < x.bits
                then types.endian.check x.endian
                else !(x ? endian)
              );
          };

          family = lib.types.create {
            name = "Family";
            description = "The kernel family.";
            merge = lib.options.merge.one;
          };

          exec = lib.types.create {
            name = "Exec";
            description = "Executable container used by the kernel";
            merge = lib.options.merge.one;
          };

          kernel = lib.types.create {
            name = "Kernel";
            description = "Kernel name and information";
            merge = lib.options.merge.one;
            check = value:
              types.exec.check value.exec
              && builtins.all types.family.check (builtins.attrValues value.families);
          };

          abi = lib.types.create {
            name = "Abi";
            description = "Binary interface for compiled code and syscalls";
            merge = lib.options.merge.one;
          };

          vendor = lib.types.create {
            name = "Vendor";
            description = "Vendor for the platform";
            merge = lib.options.merge.one;
          };
        };

        platform = lib.types.create {
          name = "system";
          description = "fully parsed representation of llvm- or nix-style platform tuple";
          merge = lib.options.merge.one;
          check = {
            cpu,
            vendor,
            kernel,
            abi,
          }:
            types.cpu.check cpu
            && types.vendor.check vendor
            && types.kernel.check kernel
            && types.abi.check abi;
        };

        endian = lib.types.enum (builtins.attrValues types.endians);

        endians = setTypes types.generic.endian {
          big = {};
          little = {};
        };

        bits = lib.types.enum [8 16 32 64 128];

        exec = lib.types.enum (builtins.attrValues types.execs);

        execs = setTypes types.generic.exec {
          aout = {}; # a.out
          elf = {};
          macho = {};
          pe = {};
          wasm = {};
          unknown = {};
        };

        vendor = lib.types.enum (builtins.attrValues types.vendors);

        vendors = setTypes types.generic.vendor {
          apple = {};
          pc = {};
          knuth = {};

          # Actually matters, unlocking some MinGW-w64-specific options in GCC. See
          # bottom of https://sourceforge.net/p/mingw-w64/wiki2/Unicode%20apps/
          w64 = {};

          none = {};
          unknown = {};
        };

        family = lib.types.enum (builtins.attrValues types.families);

        families = setTypes types.generic.family {
          bsd = {};
          darwin = {};
        };

        kernel = lib.types.enum (builtins.attrValues types.kernels);

        kernels = setTypes types.generic.kernel {
          # TODO(@Ericson2314): Don't want to mass-rebuild yet to keeping 'darwin' as
          # the normalized name for macOS.
          macos = {
            exec = types.execs.macho;
            families = {
              darwin = types.families.darwin;
            };
            name = "darwin";
          };
          ios = {
            exec = types.execs.macho;
            families = {darwin = types.families.darwin;};
          };
          # A tricky thing about FreeBSD is that there is no stable ABI across
          # versions. That means that putting in the version as part of the
          # config string is paramount.
          freebsd12 = {
            exec = types.execs.elf;
            families = {bsd = types.families.bsd;};
            name = "freebsd";
            version = 12;
          };
          freebsd13 = {
            exec = types.execs.elf;
            families = {bsd = types.families.bsd;};
            name = "freebsd";
            version = 13;
          };
          linux = {
            exec = types.execs.elf;
            families = {};
          };
          netbsd = {
            exec = types.execs.elf;
            families = {bsd = types.families.bsd;};
          };
          none = {
            exec = types.execs.unknown;
            families = {};
          };
          openbsd = {
            exec = types.execs.elf;
            families = {bsd = types.families.bsd;};
          };
          solaris = {
            exec = types.execs.elf;
            families = {};
          };
          wasi = {
            exec = types.execs.wasm;
            families = {};
          };
          redox = {
            exec = types.execs.elf;
            families = {};
          };
          windows = {
            exec = types.execs.pe;
            families = {};
          };
          ghcjs = {
            exec = types.execs.unknown;
            families = {};
          };
          genode = {
            exec = types.execs.elf;
            families = {};
          };
          mmixware = {
            exec = types.execs.unknown;
            families = {};
          };

          # aliases
          # 'darwin' is the kernel for all of them. We choose macOS by default.
          darwin = types.kernels.macos;
          watchos = types.kernels.ios;
          tvos = types.kernels.ios;
          win32 = types.kernels.windows;
        };

        cpu = lib.types.enum (builtins.attrValues types.cpus);

        cpus = setTypes types.generic.cpu {
          arm = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
          };
          armv5tel = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "5";
            arch = "armv5t";
          };
          armv6m = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "6";
            arch = "armv6-m";
          };
          armv6l = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "6";
            arch = "armv6";
          };
          armv7a = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "7";
            arch = "armv7-a";
          };
          armv7r = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "7";
            arch = "armv7-r";
          };
          armv7m = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "7";
            arch = "armv7-m";
          };
          armv7l = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "7";
            arch = "armv7";
          };
          armv8a = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "8";
            arch = "armv8-a";
          };
          armv8r = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "8";
            arch = "armv8-a";
          };
          armv8m = {
            bits = 32;
            endian = types.endians.little;
            family = "arm";
            version = "8";
            arch = "armv8-m";
          };
          aarch64 = {
            bits = 64;
            endian = types.endians.little;
            family = "arm";
            version = "8";
            arch = "armv8-a";
          };
          aarch64_be = {
            bits = 64;
            endian = types.endians.big;
            family = "arm";
            version = "8";
            arch = "armv8-a";
          };

          i386 = {
            bits = 32;
            endian = types.endians.little;
            family = "x86";
            arch = "i386";
          };
          i486 = {
            bits = 32;
            endian = types.endians.little;
            family = "x86";
            arch = "i486";
          };
          i586 = {
            bits = 32;
            endian = types.endians.little;
            family = "x86";
            arch = "i586";
          };
          i686 = {
            bits = 32;
            endian = types.endians.little;
            family = "x86";
            arch = "i686";
          };
          x86_64 = {
            bits = 64;
            endian = types.endians.little;
            family = "x86";
            arch = "x86-64";
          };

          microblaze = {
            bits = 32;
            endian = types.endians.big;
            family = "microblaze";
          };
          microblazeel = {
            bits = 32;
            endian = types.endians.little;
            family = "microblaze";
          };

          mips = {
            bits = 32;
            endian = types.endians.big;
            family = "mips";
          };
          mipsel = {
            bits = 32;
            endian = types.endians.little;
            family = "mips";
          };
          mips64 = {
            bits = 64;
            endian = types.endians.big;
            family = "mips";
          };
          mips64el = {
            bits = 64;
            endian = types.endians.little;
            family = "mips";
          };

          mmix = {
            bits = 64;
            endian = types.endians.big;
            family = "mmix";
          };

          m68k = {
            bits = 32;
            endian = types.endians.big;
            family = "m68k";
          };

          powerpc = {
            bits = 32;
            endian = types.endians.big;
            family = "power";
          };
          powerpc64 = {
            bits = 64;
            endian = types.endians.big;
            family = "power";
          };
          powerpc64le = {
            bits = 64;
            endian = types.endians.little;
            family = "power";
          };
          powerpcle = {
            bits = 32;
            endian = types.endians.little;
            family = "power";
          };

          riscv32 = {
            bits = 32;
            endian = types.endians.little;
            family = "riscv";
          };
          riscv64 = {
            bits = 64;
            endian = types.endians.little;
            family = "riscv";
          };

          s390 = {
            bits = 32;
            endian = types.endians.big;
            family = "s390";
          };
          s390x = {
            bits = 64;
            endian = types.endians.big;
            family = "s390";
          };

          sparc = {
            bits = 32;
            endian = types.endians.big;
            family = "sparc";
          };
          sparc64 = {
            bits = 64;
            endian = types.endians.big;
            family = "sparc";
          };

          wasm32 = {
            bits = 32;
            endian = types.endians.little;
            family = "wasm";
          };
          wasm64 = {
            bits = 64;
            endian = types.endians.little;
            family = "wasm";
          };

          alpha = {
            bits = 64;
            endian = types.endians.little;
            family = "alpha";
          };

          rx = {
            bits = 32;
            endian = types.endians.little;
            family = "rx";
          };
          msp430 = {
            bits = 16;
            endian = types.endians.little;
            family = "msp430";
          };
          avr = {
            bits = 8;
            family = "avr";
          };

          vc4 = {
            bits = 32;
            endian = types.endians.little;
            family = "vc4";
          };

          or1k = {
            bits = 32;
            endian = types.endians.big;
            family = "or1k";
          };

          loongarch64 = {
            bits = 64;
            endian = types.endians.little;
            family = "loongarch";
          };

          javascript = {
            bits = 32;
            endian = types.endians.little;
            family = "javascript";
          };
        };

        abi = lib.types.enum (builtins.attrValues types.abis);

        abis = setTypes types.generic.abi {
          cygnus = {};
          msvc = {};

          # Note: eabi is specific to ARM and PowerPC.
          # On PowerPC, this corresponds to PPCEABI.
          # On ARM, this corresponds to ARMEABI.
          eabi = {float = "soft";};
          eabihf = {float = "hard";};

          # Other architectures should use ELF in embedded situations.
          elf = {};

          androideabi = {};
          android = {
            assertions = [
              {
                assertion = platform: !platform.isAarch32;
                message = ''
                  The "android" ABI is not for 32-bit ARM. Use "androideabi" instead.
                '';
              }
            ];
          };

          gnueabi = {float = "soft";};
          gnueabihf = {float = "hard";};
          gnu = {
            assertions = [
              {
                assertion = platform: !platform.isAarch32;
                message = ''
                  The "gnu" ABI is ambiguous on 32-bit ARM. Use "gnueabi" or "gnueabihf" instead.
                '';
              }
              {
                assertion = platform: with platform; !(isPower64 && isBigEndian);
                message = ''
                  The "gnu" ABI is ambiguous on big-endian 64-bit PowerPC. Use "gnuabielfv2" or "gnuabielfv1" instead.
                '';
              }
            ];
          };
          gnuabi64 = {abi = "64";};
          muslabi64 = {abi = "64";};

          # NOTE: abi=n32 requires a 64-bit MIPS chip!  That is not a typo.
          # It is basically the 64-bit abi with 32-bit pointers.  Details:
          # https://www.linux-mips.org/pub/linux/mips/doc/ABI/MIPS-N32-ABI-Handbook.pdf
          gnuabin32 = {abi = "n32";};
          muslabin32 = {abi = "n32";};

          gnuabielfv2 = {abi = "elfv2";};
          gnuabielfv1 = {abi = "elfv1";};

          musleabi = {float = "soft";};
          musleabihf = {float = "hard";};
          musl = {};

          uclibceabi = {float = "soft";};
          uclibceabihf = {float = "hard";};
          uclibc = {};

          unknown = {};
        };
      };

      from = {
        string = value: let
          parts = lib.strings.split "-" value;
          skeleton = lib'.systems.skeleton parts;
          system = lib'.systems.create (lib'.systems.from.skeleton skeleton);
        in
          system;

        skeleton = spec @ {
          cpu,
          vendor ? assert false; null,
          kernel,
          abi ? assert false; null,
        }: let
          getCpu = name: types.cpus.${name} or (throw "Unknown CPU type: ${name}");
          getVendor = name: types.vendors.${name} or (throw "Unknown vendor: ${name}");
          getKernel = name: types.kernels.${name} or (throw "Unknown kernel: ${name}");
          getAbi = name: types.abis.${name} or (throw "Unknown ABI: ${name}");

          resolved = {
            cpu = getCpu spec.cpu;

            vendor =
              if spec ? vendor
              then getVendor spec.vendor
              else if lib'.systems.match.isDarwin resolved
              then types.vendors.apple
              else if lib'.systems.match.isWindows resolved
              then types.vendors.pc
              else types.vendors.unknown;

            kernel =
              if lib.strings.hasPrefix "darwin" spec.kernel
              then getKernel "darwin"
              else if lib.strings.hasPrefix "netbsd" spec.kernel
              then getKernel "netbsd"
              else getKernel spec.kernel;

            abi =
              if spec ? abi
              then getAbi spec.abi
              else if lib'.systems.match.isLinux resolved || lib'.systems.match.isWindows resolved
              then
                if lib'.systems.match.isAarch32 resolved
                then
                  if lib.versions.gte "6" (resolved.cpu.version)
                  then types.abis.gnueabihf
                  else types.abis.gnueabi
                else if lib'.systems.match.isPower64 resolved && lib'.systems.match.isBigEndian resolved
                then types.abis.gnuabielfv2
                else types.abis.gnu
              else types.abis.unknown;
          };
        in
          resolved;
      };

      into = {
        double = {
          cpu,
          kernel,
          abi,
          ...
        }: let
          kernelName = kernel.name + builtins.toString (kernel.version or "");
        in
          if abi == types.abis.cygnus
          then "${cpu.name}-cygwin"
          else if kernel.families ? darwin
          then "${cpu.name}-darwin"
          else "${cpu.name}-${kernelName}";

        triple = {
          cpu,
          vendor,
          kernel,
          abi,
          ...
        }: let
          kernelName = kernel.name + builtins.toString (kernel.version or "");
          netbsdExec =
            if
              (cpu.family == "arm" && cpu.bits == 32)
              || (cpu.family == "sparc" && cpu.bits == 32)
              || (cpu.family == "m68k" && cpu.bits == 32)
              || (cpu.family == "x86" && cpu.bits == 32)
            then types.execs.aout
            else types.execs.elf;

          exec =
            lib.strings.when
            (kernel.name == "netbsd" && netbsdExec != kernel.exec)
            kernel.exec.name;
          abi = lib.strings.when (abi != types.abis.unknown) "-${abi.name}";
        in "${cpu.name}-${vendor.name}-${kernelName}${exec}${abi}";
      };

      create = components:
        assert types.platform.check components;
          lib.types.set "system" components;

      skeleton = parts: let
        length = builtins.length parts;

        first = builtins.elemAt parts 0;
        second = builtins.elemAt parts 1;
        third = builtins.elemAt parts 2;
        fourth = builtins.elemAt parts 3;
      in
        if length == 1
        then
          if first == "avr"
          then {
            cpu = first;
            kernel = "none";
            abi = "unknown";
          }
          else builtins.throw "Target specification with 1 component is ambiguous."
        else if length == 2
        then
          if second == "cygwin"
          then {
            cpu = first;
            kernel = "windows";
            abi = "cygnus";
          }
          else if second == "windows"
          then {
            cpu = first;
            kernel = "windows";
            abi = "msvc";
          }
          else if second == "elf"
          then {
            cpu = first;
            vendor = "unkonwn";
            kernel = "none";
            abi = second;
          }
          else {
            cpu = first;
            kernel = second;
          }
        else if length == 3
        then
          if second == "linux" || (builtins.elem third ["eabi" "eabihf" "elf" "gnu"])
          then {
            cpu = first;
            vendor = "unknown";
            kernel = second;
            abi = third;
          }
          else if
            (second == "apple")
            || lib.strings.hasPrefix "freebsd" third
            || lib.strings.hasPrefix "netbsd" third
            || lib.strings.hasPrefix "genode" third
            || (builtins.elem third ["wasi" "redox" "mmixware" "ghcjs" "mingw32"])
          then {
            cpu = first;
            vendor = second;
            kernel =
              if third == "mingw32"
              then "windows"
              else third;
          }
          else builtins.throw "Target specification with 3 components is ambiguous."
        else if length == 4
        then {
          cpu = first;
          vendor = second;
          kernel = third;
          abi = fourth;
        }
        else builtins.throw "Invalid component count for creating system skeleton. Expected 1-4, but got ${builtins.toString length}.";

      patterns = {
        isi686 = {cpu = types.cpus.i686;};
        isx86_32 = {
          cpu = {
            family = "x86";
            bits = 32;
          };
        };
        isx86_64 = {
          cpu = {
            family = "x86";
            bits = 64;
          };
        };
        isPower = {cpu = {family = "power";};};
        isPower64 = {
          cpu = {
            family = "power";
            bits = 64;
          };
        };
        # This ABI is the default in NixOS PowerPC64 BE, but not on mainline GCC,
        # so it sometimes causes issues in certain packages that makes the wrong
        # assumption on the used ABI.
        isAbiElfv2 = [
          {abi = {abi = "elfv2";};}
          {
            abi = {name = "musl";};
            cpu = {
              family = "power";
              bits = 64;
            };
          }
        ];
        isx86 = {cpu = {family = "x86";};};
        isAarch32 = {
          cpu = {
            family = "arm";
            bits = 32;
          };
        };
        isArmv7 =
          map ({arch, ...}: {cpu = {inherit arch;};})
          (lib.filter (cpu: lib.hasPrefix "armv7" cpu.arch or "")
            (lib.attrValues types.cpus));
        isAarch64 = {
          cpu = {
            family = "arm";
            bits = 64;
          };
        };
        isAarch = {cpu = {family = "arm";};};
        isMicroBlaze = {cpu = {family = "microblaze";};};
        isMips = {cpu = {family = "mips";};};
        isMips32 = {
          cpu = {
            family = "mips";
            bits = 32;
          };
        };
        isMips64 = {
          cpu = {
            family = "mips";
            bits = 64;
          };
        };
        isMips64n32 = {
          cpu = {
            family = "mips";
            bits = 64;
          };
          abi = {abi = "n32";};
        };
        isMips64n64 = {
          cpu = {
            family = "mips";
            bits = 64;
          };
          abi = {abi = "64";};
        };
        isMmix = {cpu = {family = "mmix";};};
        isRiscV = {cpu = {family = "riscv";};};
        isRiscV32 = {
          cpu = {
            family = "riscv";
            bits = 32;
          };
        };
        isRiscV64 = {
          cpu = {
            family = "riscv";
            bits = 64;
          };
        };
        isRx = {cpu = {family = "rx";};};
        isSparc = {cpu = {family = "sparc";};};
        isWasm = {cpu = {family = "wasm";};};
        isMsp430 = {cpu = {family = "msp430";};};
        isVc4 = {cpu = {family = "vc4";};};
        isAvr = {cpu = {family = "avr";};};
        isAlpha = {cpu = {family = "alpha";};};
        isOr1k = {cpu = {family = "or1k";};};
        isM68k = {cpu = {family = "m68k";};};
        isS390 = {cpu = {family = "s390";};};
        isS390x = {
          cpu = {
            family = "s390";
            bits = 64;
          };
        };
        isLoongArch64 = {
          cpu = {
            family = "loongarch";
            bits = 64;
          };
        };
        isJavaScript = {cpu = types.cpus.javascript;};

        is32bit = {cpu = {bits = 32;};};
        is64bit = {cpu = {bits = 64;};};
        isILP32 = builtins.map (a: {abi = {abi = a;};}) ["n32" "ilp32" "x32"];
        isBigEndian = {cpu = {endian = types.endians.big;};};
        isLittleEndian = {cpu = {endian = types.endians.little;};};

        isBSD = {kernel = {families = {bsd = types.families.bsd;};};};
        isDarwin = {kernel = {families = {darwin = types.families.darwin;};};};
        isUnix = [lib'.systems.match.isBSD lib'.systems.match.isDarwin lib'.systems.match.isLinux lib'.systems.match.isSunOS lib'.systems.match.isCygwin lib'.systems.match.isRedox];

        isMacOS = {kernel = types.kernels.macos;};
        isiOS = {kernel = types.kernels.ios;};
        isLinux = {kernel = types.kernels.linux;};
        isSunOS = {kernel = types.kernels.solaris;};
        isFreeBSD = {kernel = {name = "freebsd";};};
        isNetBSD = {kernel = types.kernels.netbsd;};
        isOpenBSD = {kernel = types.kernels.openbsd;};
        isWindows = {kernel = types.kernels.windows;};
        isCygwin = {
          kernel = types.kernels.windows;
          abi = types.abis.cygnus;
        };
        isMinGW = {
          kernel = types.kernels.windows;
          abi = types.abis.gnu;
        };
        isWasi = {kernel = types.kernels.wasi;};
        isRedox = {kernel = types.kernels.redox;};
        isGhcjs = {kernel = types.kernels.ghcjs;};
        isGenode = {kernel = types.kernels.genode;};
        isNone = {kernel = types.kernels.none;};

        isAndroid = [{abi = types.abis.android;} {abi = types.abis.androideabi;}];
        isGnu = builtins.map (value: {abi = value;}) [types.abis.gnuabi64 types.abis.gnuabin32 types.abis.gnu types.abis.gnueabi types.abis.gnueabihf types.abis.gnuabielfv1 types.abis.gnuabielfv2];
        isMusl = builtins.map (value: {abi = value;}) [types.abis.musl types.abis.musleabi types.abis.musleabihf types.abis.muslabin32 types.abis.muslabi64];
        isUClibc = builtins.map (value: {abi = value;}) [types.abis.uclibc types.abis.uclibceabi types.abis.uclibceabihf];

        isEfi = [
          {
            cpu = {
              family = "arm";
              version = "6";
            };
          }
          {
            cpu = {
              family = "arm";
              version = "7";
            };
          }
          {
            cpu = {
              family = "arm";
              version = "8";
            };
          }
          {cpu = {family = "riscv";};}
          {cpu = {family = "x86";};}
        ];
      };
    };
  };
}
