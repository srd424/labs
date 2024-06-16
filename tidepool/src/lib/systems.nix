{
  lib,
  config,
}: let
  lib' = config.lib;
  types = config.lib.systems.types;

  setTypes = type: let
    assign = name: value:
      assert lib.errors.trace (type.check value) "${name} is not of type ${type.name}: ${lib.generators.pretty {} value}";
        lib.types.set type.name ({inherit name;} // value);
  in
    builtins.mapAttrs assign;

  matchAnyAttrs = patterns:
    if builtins.isList patterns
    then value: builtins.any (pattern: lib.attrs.match pattern value) patterns
    else lib.attrs.match patterns;

  getDoubles = predicate:
    builtins.map
    lib'.systems.into.double
    (builtins.filter predicate lib'.systems.doubles.all);
in {
  config = {
    lib.systems = {
      match = builtins.mapAttrs (lib.fp.const matchAnyAttrs) lib'.systems.patterns;

      platforms = {
        pc = {
          linux-kernel = {
            name = "pc";

            baseConfig = "defconfig";
            # Build whatever possible as a module, if not stated in the extra config.
            autoModules = true;
            target = "bzImage";
          };
        };

        pc_simplekernel = lib.attrs.mergeRecursive lib'.systems.platforms.pc {
          linux-kernel.autoModules = false;
        };

        powernv = {
          linux-kernel = {
            name = "PowerNV";

            baseConfig = "powernv_defconfig";
            target = "vmlinux";
            autoModules = true;
            # avoid driver/FS trouble arising from unusual page size
            extraConfig = ''
              PPC_64K_PAGES n
              PPC_4K_PAGES y
              IPV6 y

              ATA_BMDMA y
              ATA_SFF y
              VIRTIO_MENU y
            '';
          };
        };

        ##
        ## ARM
        ##

        pogoplug4 = {
          linux-kernel = {
            name = "pogoplug4";

            baseConfig = "multi_v5_defconfig";
            autoModules = false;
            extraConfig = ''
              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n
            '';
            makeFlags = ["LOADADDR=0x8000"];
            target = "uImage";
            # TODO reenable once manual-config's config actually builds a .dtb and this is checked to be working
            #DTB = true;
          };
          gcc = {
            arch = "armv5te";
          };
        };

        sheevaplug = {
          linux-kernel = {
            name = "sheevaplug";

            baseConfig = "multi_v5_defconfig";
            autoModules = false;
            extraConfig = ''
              BLK_DEV_RAM y
              BLK_DEV_INITRD y
              BLK_DEV_CRYPTOLOOP m
              BLK_DEV_DM m
              DM_CRYPT m
              MD y
              REISERFS_FS m
              BTRFS_FS m
              XFS_FS m
              JFS_FS m
              EXT4_FS m
              USB_STORAGE_CYPRESS_ATACB m

              # mv cesa requires this sw fallback, for mv-sha1
              CRYPTO_SHA1 y
              # Fast crypto
              CRYPTO_TWOFISH y
              CRYPTO_TWOFISH_COMMON y
              CRYPTO_BLOWFISH y
              CRYPTO_BLOWFISH_COMMON y

              IP_PNP y
              IP_PNP_DHCP y
              NFS_FS y
              ROOT_NFS y
              TUN m
              NFS_V4 y
              NFS_V4_1 y
              NFS_FSCACHE y
              NFSD m
              NFSD_V2_ACL y
              NFSD_V3 y
              NFSD_V3_ACL y
              NFSD_V4 y
              NETFILTER y
              IP_NF_IPTABLES y
              IP_NF_FILTER y
              IP_NF_MATCH_ADDRTYPE y
              IP_NF_TARGET_LOG y
              IP_NF_MANGLE y
              IPV6 m
              VLAN_8021Q m

              CIFS y
              CIFS_XATTR y
              CIFS_POSIX y
              CIFS_FSCACHE y
              CIFS_ACL y

              WATCHDOG y
              WATCHDOG_CORE y
              ORION_WATCHDOG m

              ZRAM m
              NETCONSOLE m

              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n

              # Fail to build
              DRM n
              SCSI_ADVANSYS n
              USB_ISP1362_HCD n
              SND_SOC n
              SND_ALI5451 n
              FB_SAVAGE n
              SCSI_NSP32 n
              ATA_SFF n
              SUNGEM n
              IRDA n
              ATM_HE n
              SCSI_ACARD n
              BLK_DEV_CMD640_ENHANCED n

              FUSE_FS m

              # systemd uses cgroups
              CGROUPS y

              # Latencytop
              LATENCYTOP y

              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n

              # Kdb, for kernel troubles
              KGDB y
              KGDB_SERIAL_CONSOLE y
              KGDB_KDB y
            '';
            makeFlags = ["LOADADDR=0x0200000"];
            target = "uImage";
            DTB = true; # Beyond 3.10
          };
          gcc = {
            arch = "armv5te";
          };
        };

        raspberrypi = {
          linux-kernel = {
            name = "raspberrypi";

            baseConfig = "bcm2835_defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            extraConfig = ''
              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n
            '';
            target = "zImage";
          };
          gcc = {
            arch = "armv6";
            fpu = "vfp";
          };
        };

        # Legacy attribute, for compatibility with existing configs only.
        raspberrypi2 = lib'.systems.platforms.armv7l-hf-multiplatform;

        # Nvidia Bluefield 2 (w. crypto support)
        bluefield2 = {
          gcc = {
            arch = "armv8-a+fp+simd+crc+crypto";
          };
        };

        zero-gravitas = {
          linux-kernel = {
            name = "zero-gravitas";

            baseConfig = "zero-gravitas_defconfig";
            # Target verified by checking /boot on reMarkable 1 device
            target = "zImage";
            autoModules = false;
            DTB = true;
          };
          gcc = {
            fpu = "neon";
            cpu = "cortex-a9";
          };
        };

        zero-sugar = {
          linux-kernel = {
            name = "zero-sugar";

            baseConfig = "zero-sugar_defconfig";
            DTB = true;
            autoModules = false;
            preferBuiltin = true;
            target = "zImage";
          };
          gcc = {
            cpu = "cortex-a7";
            fpu = "neon-vfpv4";
            float-abi = "hard";
          };
        };

        utilite = {
          linux-kernel = {
            name = "utilite";
            maseConfig = "multi_v7_defconfig";
            autoModules = false;
            extraConfig = ''
              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n
            '';
            makeFlags = ["LOADADDR=0x10800000"];
            target = "uImage";
            DTB = true;
          };
          gcc = {
            cpu = "cortex-a9";
            fpu = "neon";
          };
        };

        guruplug = lib.recursiveUpdate lib'.systems.platforms.sheevaplug {
          # Define `CONFIG_MACH_GURUPLUG' (see
          # <http://kerneltrap.org/mailarchive/git-commits-head/2010/5/19/33618>)
          # and other GuruPlug-specific things.  Requires the `guruplug-defconfig'
          # patch.
          linux-kernel.baseConfig = "guruplug_defconfig";
        };

        beaglebone = lib.recursiveUpdate lib'.systems.platforms.armv7l-hf-multiplatform {
          linux-kernel = {
            name = "beaglebone";
            baseConfig = "bb.org_defconfig";
            autoModules = false;
            extraConfig = ""; # TBD kernel config
            target = "zImage";
          };
        };

        # https://developer.android.com/ndk/guides/abis#v7a
        armv7a-android = {
          linux-kernel.name = "armeabi-v7a";
          gcc = {
            arch = "armv7-a";
            float-abi = "softfp";
            fpu = "vfpv3-d16";
          };
        };

        armv7l-hf-multiplatform = {
          linux-kernel = {
            name = "armv7l-hf-multiplatform";
            Major = "2.6"; # Using "2.6" enables 2.6 kernel syscalls in glibc.
            baseConfig = "multi_v7_defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            target = "zImage";
            extraConfig = ''
              # Serial port for Raspberry Pi 3. Wasn't included in ARMv7 defconfig
              # until 4.17.
              SERIAL_8250_BCM2835AUX y
              SERIAL_8250_EXTENDED y
              SERIAL_8250_SHARE_IRQ y

              # Hangs ODROID-XU4
              ARM_BIG_LITTLE_CPUIDLE n

              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n

              # >=5.12 fails with:
              # drivers/net/ethernet/micrel/ks8851_common.o: in function `ks8851_probe_common':
              # ks8851_common.c:(.text+0x179c): undefined reference to `__this_module'
              # See: https://lore.kernel.org/netdev/20210116164828.40545-1-marex@denx.de/T/
              KS8851_MLL y
            '';
          };
          gcc = {
            # Some table about fpu flags:
            # http://community.arm.com/servlet/JiveServlet/showImage/38-1981-3827/blogentry-103749-004812900+1365712953_thumb.png
            # Cortex-A5: -mfpu=neon-fp16
            # Cortex-A7 (rpi2): -mfpu=neon-vfpv4
            # Cortex-A8 (beaglebone): -mfpu=neon
            # Cortex-A9: -mfpu=neon-fp16
            # Cortex-A15: -mfpu=neon-vfpv4

            # More about FPU:
            # https://wiki.debian.org/ArmHardFloatPort/VfpComparison

            # vfpv3-d16 is what Debian uses and seems to be the best compromise: NEON is not supported in e.g. Scaleway or Tegra 2,
            # and the above page suggests NEON is only an improvement with hand-written assembly.
            arch = "armv7-a";
            fpu = "vfpv3-d16";

            # For Raspberry Pi the 2 the best would be:
            #   cpu = "cortex-a7";
            #   fpu = "neon-vfpv4";
          };
        };

        aarch64-multiplatform = {
          linux-kernel = {
            name = "aarch64-multiplatform";
            baseConfig = "defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            extraConfig = ''
              # Raspberry Pi 3 stuff. Not needed for   s >= 4.10.
              ARCH_BCM2835 y
              BCM2835_MBOX y
              BCM2835_WDT y
              RASPBERRYPI_FIRMWARE y
              RASPBERRYPI_POWER y
              SERIAL_8250_BCM2835AUX y
              SERIAL_8250_EXTENDED y
              SERIAL_8250_SHARE_IRQ y

              # Cavium ThunderX stuff.
              PCI_HOST_THUNDER_ECAM y

              # Nvidia Tegra stuff.
              PCI_TEGRA y

              # The default (=y) forces us to have the XHCI firmware available in initrd,
              # which our initrd builder can't currently do easily.
              USB_XHCI_TEGRA m
            '';
            target = "Image";
          };
          gcc = {
            arch = "armv8-a";
          };
        };

        apple-m1 = {
          gcc = {
            arch = "armv8.3-a+crypto+sha2+aes+crc+fp16+lse+simd+ras+rdm+rcpc";
            cpu = "apple-a13";
          };
        };

        ##
        ## MIPS
        ##

        ben_nanonote = {
          linux-kernel = {
            name = "ben_nanonote";
          };
          gcc = {
            arch = "mips32";
            float = "soft";
          };
        };

        fuloong2f_n32 = {
          linux-kernel = {
            name = "fuloong2f_n32";
            baseConfig = "lemote2f_defconfig";
            autoModules = false;
            extraConfig = ''
              MIGRATION n
              COMPACTION n

              # nixos mounts some cgroup
              CGROUPS y

              BLK_DEV_RAM y
              BLK_DEV_INITRD y
              BLK_DEV_CRYPTOLOOP m
              BLK_DEV_DM m
              DM_CRYPT m
              MD y
              REISERFS_FS m
              EXT4_FS m
              USB_STORAGE_CYPRESS_ATACB m

              IP_PNP y
              IP_PNP_DHCP y
              IP_PNP_BOOTP y
              NFS_FS y
              ROOT_NFS y
              TUN m
              NFS_V4 y
              NFS_V4_1 y
              NFS_FSCACHE y
              NFSD m
              NFSD_V2_ACL y
              NFSD_V3 y
              NFSD_V3_ACL y
              NFSD_V4 y

              # Fail to build
              DRM n
              SCSI_ADVANSYS n
              USB_ISP1362_HCD n
              SND_SOC n
              SND_ALI5451 n
              FB_SAVAGE n
              SCSI_NSP32 n
              ATA_SFF n
              SUNGEM n
              IRDA n
              ATM_HE n
              SCSI_ACARD n
              BLK_DEV_CMD640_ENHANCED n

              FUSE_FS m

              # Needed for udev >= 150
              SYSFS_DEPRECATED_V2 n

              VGA_CONSOLE n
              VT_HW_CONSOLE_BINDING y
              SERIAL_8250_CONSOLE y
              FRAMEBUFFER_CONSOLE y
              EXT2_FS y
              EXT3_FS y
              REISERFS_FS y
              MAGIC_SYSRQ y

              # The kernel doesn't boot at all, with FTRACE
              FTRACE n
            '';
            target = "vmlinux";
          };
          gcc = {
            arch = "loongson2f";
            float = "hard";
            abi = "n32";
          };
        };

        # can execute on 32bit chip
        gcc_mips32r2_o32 = {
          gcc = {
            arch = "mips32r2";
            abi = "32";
          };
        };
        gcc_mips32r6_o32 = {
          gcc = {
            arch = "mips32r6";
            abi = "32";
          };
        };
        gcc_mips64r2_n32 = {
          gcc = {
            arch = "mips64r2";
            abi = "n32";
          };
        };
        gcc_mips64r6_n32 = {
          gcc = {
            arch = "mips64r6";
            abi = "n32";
          };
        };
        gcc_mips64r2_64 = {
          gcc = {
            arch = "mips64r2";
            abi = "64";
          };
        };
        gcc_mips64r6_64 = {
          gcc = {
            arch = "mips64r6";
            abi = "64";
          };
        };

        # based on:
        #   https://www.mail-archive.com/qemu-discuss@nongnu.org/msg05179.html
        #   https://gmplib.org/~tege/qemu.html#mips64-debian
        mips64el-qemu-linux-gnuabi64 = {
          linux-kernel = {
            name = "mips64el";
            baseConfig = "64r2el_defconfig";
            target = "vmlinuz";
            autoModules = false;
            DTB = true;
            # for qemu 9p passthrough filesystem
            extraConfig = ''
              MIPS_MALTA y
              PAGE_SIZE_4KB y
              CPU_LITTLE_ENDIAN y
              CPU_MIPS64_R2 y
              64BIT y
              CPU_MIPS64_R2 y

              NET_9P y
              NET_9P_VIRTIO y
              9P_FS y
              9P_FS_POSIX_ACL y
              PCI y
              VIRTIO_PCI y
            '';
          };
        };

        ##
        ## Other
        ##

        riscv-multiplatform = {
          linux-kernel = {
            name = "riscv-multiplatform";
            target = "Image";
            autoModules = true;
            baseConfig = "defconfig";
            DTB = true;
            extraConfig = ''
              SERIAL_OF_PLATFORM y
            '';
          };
        };

        mipsel-linux-gnu =
          {
            triple = "mipsel-unknown-linux-gnu";
          }
          // lib'.systems.platforms.gcc_mips32r2_o32;

        # This function takes a minimally-valid "platform" and returns an
        # attrset containing zero or more additional attrs which should be
        # included in the platform in order to further elaborate it.
        select = platform:
        # x86
        /**/
          if platform.isx86
          then lib'.systems.platforms.pc
          # ARM
          else if platform.isAarch32
          then let
            version = platform.system.cpu.version or null;
          in
            if version == null
            then lib'.systems.platforms.pc
            else if lib.versions.gte "6" version
            then lib'.systems.platforms.sheevaplug
            else if lib.versions.gte "7" version
            then lib'.systems.platforms.raspberrypi
            else lib'.systems.platforms.armv7l-hf-multiplatform
          else if platform.isAarch64
          then
            if platform.isDarwin
            then lib'.systems.platforms.apple-m1
            else lib'.systems.platforms.aarch64-multiplatform
          else if platform.isRiscV
          then lib'.systems.platforms.riscv-multiplatform
          else if platform.system.cpu == types.cpus.mipsel
          then lib'.systems.platforms.mipsel-linux-gnu
          else if platform.system.cpu == types.cpus.powerpc64le
          then lib'.systems.platforms.powernv
          else {};
      };

      architectures = {
        features = {
          # x86_64 Generic
          # Spec: https://gitlab.com/x86-psABIs/x86-64-ABI/
          default = [];
          x86-64 = [];
          x86-64-v2 = ["sse3" "ssse3" "sse4_1" "sse4_2"];
          x86-64-v3 = ["sse3" "ssse3" "sse4_1" "sse4_2" "avx" "avx2" "fma"];
          x86-64-v4 = ["sse3" "ssse3" "sse4_1" "sse4_2" "avx" "avx2" "avx512" "fma"];
          # x86_64 Intel
          nehalem = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes"];
          westmere = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes"];
          sandybridge = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx"];
          ivybridge = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx"];
          haswell = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "fma"];
          broadwell = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "fma"];
          skylake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "fma"];
          skylake-avx512 = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          cannonlake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          icelake-client = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          icelake-server = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          cascadelake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          cooperlake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          tigerlake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "avx512" "fma"];
          alderlake = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx" "avx2" "fma"];
          # x86_64 AMD
          btver1 = ["sse3" "ssse3" "sse4_1" "sse4_2"];
          btver2 = ["sse3" "ssse3" "sse4_1" "sse4_2" "aes" "avx"];
          bdver1 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "fma" "fma4"];
          bdver2 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "fma" "fma4"];
          bdver3 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "fma" "fma4"];
          bdver4 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2" "fma" "fma4"];
          znver1 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2" "fma"];
          znver2 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2" "fma"];
          znver3 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2" "fma"];
          znver4 = ["sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2" "avx512" "fma"];
          # other
          armv5te = [];
          armv6 = [];
          armv7-a = [];
          armv8-a = [];
          mips32 = [];
          loongson2f = [];
        };

        # a superior CPU has all the features of an inferior and is able to build and test code for it
        inferiors = {
          # x86_64 Generic
          default = [];
          x86-64 = [];
          x86-64-v2 = ["x86-64"];
          x86-64-v3 = ["x86-64-v2"] ++ lib'.systems.architectures.inferiors.x86-64-v2;
          x86-64-v4 = ["x86-64-v3"] ++ lib'.systems.architectures.inferiors.x86-64-v3;

          # x86_64 Intel
          # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
          nehalem = ["x86-64-v2"] ++ lib'.systems.architectures.inferiors.x86-64-v2;
          westmere = ["nehalem"] ++ lib'.systems.architectures.inferiors.nehalem;
          sandybridge = ["westmere"] ++ lib'.systems.architectures.inferiors.westmere;
          ivybridge = ["sandybridge"] ++ lib'.systems.architectures.inferiors.sandybridge;

          haswell = lib.unique (["ivybridge" "x86-64-v3"] ++ lib'.systems.architectures.inferiors.ivybridge ++ lib'.systems.architectures.inferiors.x86-64-v3);
          broadwell = ["haswell"] ++ lib'.systems.architectures.inferiors.haswell;
          skylake = ["broadwell"] ++ lib'.systems.architectures.inferiors.broadwell;

          skylake-avx512 = lib.unique (["skylake" "x86-64-v4"] ++ lib'.systems.architectures.inferiors.skylake ++ lib'.systems.architectures.inferiors.x86-64-v4);
          cannonlake = ["skylake-avx512"] ++ lib'.systems.architectures.inferiors.skylake-avx512;
          icelake-client = ["cannonlake"] ++ lib'.systems.architectures.inferiors.cannonlake;
          icelake-server = ["icelake-client"] ++ lib'.systems.architectures.inferiors.icelake-client;
          cascadelake = ["cannonlake"] ++ lib'.systems.architectures.inferiors.cannonlake;
          cooperlake = ["cascadelake"] ++ lib'.systems.architectures.inferiors.cascadelake;
          tigerlake = ["icelake-server"] ++ lib'.systems.architectures.inferiors.icelake-server;

          # CX16 does not exist on alderlake, while it does on nearly all other intel CPUs
          alderlake = [];

          # x86_64 AMD
          # TODO: fill this (need testing)
          btver1 = [];
          btver2 = [];
          bdver1 = [];
          bdver2 = [];
          bdver3 = [];
          bdver4 = [];
          # Regarding `skylake` as inferior of `znver1`, there are reports of
          # successful usage by Gentoo users and Phoronix benchmarking of different
          # `-march` targets.
          #
          # The GCC documentation on extensions used and wikichip documentation
          # regarding supperted extensions on znver1 and skylake was used to create
          # this partial order.
          #
          # Note:
          #
          # - The successors of `skylake` (`cannonlake`, `icelake`, etc) use `avx512`
          #   which no current AMD Zen michroarch support.
          # - `znver1` uses `ABM`, `CLZERO`, `CX16`, `MWAITX`, and `SSE4A` which no
          #   current Intel microarch support.
          #
          # https://www.phoronix.com/scan.php?page=article&item=amd-znver3-gcc11&num=1
          # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
          # https://en.wikichip.org/wiki/amd/microarchitectures/zen
          # https://en.wikichip.org/wiki/intel/microarchitectures/skylake
          znver1 = ["skylake"] ++ lib'.systems.architectures.inferiors.skylake; # Includes haswell and x86-64-v3
          znver2 = ["znver1"] ++ lib'.systems.architectures.inferiors.znver1;
          znver3 = ["znver2"] ++ lib'.systems.architectures.inferiors.znver2;
          znver4 = lib.unique (["znver3" "x86-64-v4"] ++ lib'.systems.architectures.inferiors.znver3 ++ lib'.systems.architectures.inferiors.x86-64-v4);

          # other
          armv5te = [];
          armv6 = [];
          armv7-a = [];
          armv8-a = [];
          mips32 = [];
          loongson2f = [];
        };
      };

      validate = {
        architecture = let
          isSupported = feature: x:
            builtins.elem feature (lib'.systems.architectures.features.${x} or []);
        in {
          sse3Support = isSupported "sse3";
          ssse3Support = isSupported "ssse3";
          sse4_1Support = isSupported "sse4_1";
          sse4_2Support = isSupported "sse4_2";
          sse4_aSupport = isSupported "sse4a";
          avxSupport = isSupported "avx";
          avx2Support = isSupported "avx2";
          avx512Support = isSupported "avx512";
          aesSupport = isSupported "aes";
          fmaSupport = isSupported "fma";
          fma4Support = isSupported "fma4";
        };

        compatible = a: b:
          lib.any lib.id [
            # x86
            (b == lib'.systems.types.cpus.i386 && lib'.systems.validate.compatible a lib'.systems.types.cpus.i486)
            (b == lib'.systems.types.cpus.i486 && lib'.systems.validate.compatible a lib'.systems.types.cpus.i586)
            (b == lib'.systems.types.cpus.i586 && lib'.systems.validate.compatible a lib'.systems.types.cpus.i686)

            # XXX: Not true in some cases. Like in WSL mode.
            (b == lib'.systems.types.cpus.i686 && lib'.systems.validate.compatible a lib'.systems.types.cpus.x86_64)

            # ARMv4
            (b == lib'.systems.types.cpus.arm && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv5tel)

            # ARMv5
            (b == lib'.systems.types.cpus.armv5tel && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv6l)

            # ARMv6
            (b == lib'.systems.types.cpus.armv6l && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv6m)
            (b == lib'.systems.types.cpus.armv6m && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv7l)

            # ARMv7
            (b == lib'.systems.types.cpus.armv7l && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv7a)
            (b == lib'.systems.types.cpus.armv7l && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv7r)
            (b == lib'.systems.types.cpus.armv7l && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv7m)

            # ARMv8
            (b == lib'.systems.types.cpus.aarch64 && a == lib'.systems.types.cpus.armv8a)
            (b == lib'.systems.types.cpus.armv8a && lib'.systems.validate.compatible a lib'.systems.types.cpus.aarch64)
            (b == lib'.systems.types.cpus.armv8r && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv8a)
            (b == lib'.systems.types.cpus.armv8m && lib'.systems.validate.compatible a lib'.systems.types.cpus.armv8a)

            # PowerPC
            (b == lib'.systems.types.cpus.powerpc && lib'.systems.validate.compatible a lib'.systems.types.cpus.powerpc64)
            (b == lib'.systems.types.cpus.powerpcle && lib'.systems.validate.compatible a lib'.systems.types.cpus.powerpc64le)

            # MIPS
            (b == lib'.systems.types.cpus.mips && lib'.systems.validate.compatible a lib'.systems.types.cpus.mips64)
            (b == lib'.systems.types.cpus.mipsel && lib'.systems.validate.compatible a lib'.systems.types.cpus.mips64el)

            # RISCV
            (b == lib'.systems.types.cpus.riscv32 && lib'.systems.validate.compatible a lib'.systems.types.cpus.riscv64)

            # SPARC
            (b == lib'.systems.types.cpus.sparc && lib'.systems.validate.compatible a lib'.systems.types.cpus.sparc64)

            # WASM
            (b == lib'.systems.types.cpus.wasm32 && lib'.systems.validate.compatible a lib'.systems.types.cpus.wasm64)

            # identity
            (b == a)
          ];
      };

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
          abi' = lib.strings.when (abi != types.abis.unknown) "-${abi.name}";
        in "${cpu.name}-${vendor.name}-${kernelName}${exec}${abi'}";
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

      doubles = {
        resolved = builtins.map lib'.systems.from.string lib'.systems.doubles.all;

        all = [
          # Cygwin
          "i686-cygwin"
          "x86_64-cygwin"

          # Darwin
          "x86_64-darwin"
          "i686-darwin"
          "aarch64-darwin"
          "armv7a-darwin"

          # FreeBSD
          "i686-freebsd13"
          "x86_64-freebsd13"

          # Genode
          "aarch64-genode"
          "i686-genode"
          "x86_64-genode"

          # illumos
          "x86_64-solaris"

          # JS
          "javascript-ghcjs"

          # Linux
          "aarch64-linux"
          "armv5tel-linux"
          "armv6l-linux"
          "armv7a-linux"
          "armv7l-linux"
          "i686-linux"
          "loongarch64-linux"
          "m68k-linux"
          "microblaze-linux"
          "microblazeel-linux"
          "mips-linux"
          "mips64-linux"
          "mips64el-linux"
          "mipsel-linux"
          "powerpc64-linux"
          "powerpc64le-linux"
          "riscv32-linux"
          "riscv64-linux"
          "s390-linux"
          "s390x-linux"
          "x86_64-linux"

          # MMIXware
          "mmix-mmixware"

          # NetBSD
          "aarch64-netbsd"
          "armv6l-netbsd"
          "armv7a-netbsd"
          "armv7l-netbsd"
          "i686-netbsd"
          "m68k-netbsd"
          "mipsel-netbsd"
          "powerpc-netbsd"
          "riscv32-netbsd"
          "riscv64-netbsd"
          "x86_64-netbsd"

          # none
          "aarch64_be-none"
          "aarch64-none"
          "arm-none"
          "armv6l-none"
          "avr-none"
          "i686-none"
          "microblaze-none"
          "microblazeel-none"
          "mips-none"
          "mips64-none"
          "msp430-none"
          "or1k-none"
          "m68k-none"
          "powerpc-none"
          "powerpcle-none"
          "riscv32-none"
          "riscv64-none"
          "rx-none"
          "s390-none"
          "s390x-none"
          "vc4-none"
          "x86_64-none"

          # OpenBSD
          "i686-openbsd"
          "x86_64-openbsd"

          # Redox
          "x86_64-redox"

          # WASI
          "wasm64-wasi"
          "wasm32-wasi"

          # Windows
          "x86_64-windows"
          "i686-windows"
        ];

        arm = getDoubles lib'.systems.match.isAarch32;
        armv7 = getDoubles lib'.systems.match.isArmv7;
        aarch64 = getDoubles lib'.systems.match.isAarch64;
        x86 = getDoubles lib'.systems.match.isx86;
        i686 = getDoubles lib'.systems.match.isi686;
        x86_64 = getDoubles lib'.systems.match.isx86_64;
        microblaze = getDoubles lib'.systems.match.isMicroBlaze;
        mips = getDoubles lib'.systems.match.isMips;
        mmix = getDoubles lib'.systems.match.isMmix;
        power = getDoubles lib'.systems.match.isPower;
        riscv = getDoubles lib'.systems.match.isRiscV;
        riscv32 = getDoubles lib'.systems.match.isRiscV32;
        riscv64 = getDoubles lib'.systems.match.isRiscV64;
        rx = getDoubles lib'.systems.match.isRx;
        vc4 = getDoubles lib'.systems.match.isVc4;
        or1k = getDoubles lib'.systems.match.isOr1k;
        m68k = getDoubles lib'.systems.match.isM68k;
        s390 = getDoubles lib'.systems.match.isS390;
        s390x = getDoubles lib'.systems.match.isS390x;
        loongarch64 = getDoubles lib'.systems.match.isLoongArch64;
        js = getDoubles lib'.systems.match.isJavaScript;

        bigEndian = getDoubles lib'.systems.match.isBigEndian;
        littleEndian = getDoubles lib'.systems.match.isLittleEndian;

        cygwin = getDoubles lib'.systems.match.isCygwin;
        darwin = getDoubles lib'.systems.match.isDarwin;
        freebsd = getDoubles lib'.systems.match.isFreeBSD;
        # Should be better, but MinGW is unclear.
        gnu =
          getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnu;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnueabi;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnueabihf;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnuabin32;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnuabi64;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnuabielfv1;
          })
          ++ getDoubles (lib.attrs.match {
            kernel = types.kernels.linux;
            abi = types.abis.gnuabielfv2;
          });
        illumos = getDoubles lib'.systems.match.isSunOS;
        linux = getDoubles lib'.systems.match.isLinux;
        netbsd = getDoubles lib'.systems.match.isNetBSD;
        openbsd = getDoubles lib'.systems.match.isOpenBSD;
        unix = getDoubles lib'.systems.match.isUnix;
        wasi = getDoubles lib'.systems.match.isWasi;
        redox = getDoubles lib'.systems.match.isRedox;
        windows = getDoubles lib'.systems.match.isWindows;
        genode = getDoubles lib'.systems.match.isGenode;

        embedded = getDoubles lib'.systems.match.isNone;

        mesaPlatforms = ["i686-linux" "x86_64-linux" "x86_64-darwin" "armv5tel-linux" "armv6l-linux" "armv7l-linux" "armv7a-linux" "aarch64-linux" "powerpc64-linux" "powerpc64le-linux" "aarch64-darwin" "riscv64-linux"];
      };

      withBuildInfo = args: let
        settings =
          if builtins.isString args
          then {system = args;}
          else args;

        resolved =
          {
            system = lib'.systems.from.string (
              if settings ? triple
              then settings.triple
              else settings.system
            );

            inherit
              ({
                  linux-kernel = settings.linux-kernel or {};
                  gcc = settings.gcc or {};
                  rustc = settings.rustc or {};
                }
                // lib'.systems.platforms.select resolved)
              linux-kernel
              gcc
              rust
              ;

            double = lib'.systems.into.double resolved.system;
            triple = lib'.systems.into.triple resolved.system;

            isExecutable = platform:
              (resolved.isAndroid == platform.isAndroid)
              && resolved.system.kernel == platform.system.kernel
              && lib'.systems.validate.compatible resolved.system.cpu platform.system.cpu;

            # The difference between `isStatic` and `hasSharedLibraries` is mainly the
            # addition of the `staticMarker` (see make-derivation.nix).  Some
            # platforms, like embedded machines without a libc (e.g. arm-none-eabi)
            # don't support dynamic linking, but don't get the `staticMarker`.
            # `pkgsStatic` sets `isStatic=true`, so `pkgsStatic.hostPlatform` always
            # has the `staticMarker`.
            isStatic = resolved.isWasm || resolved.isRedox;

            # It is important that hasSharedLibraries==false when the platform has no
            # dynamic library loader.  Various tools (including the gcc build system)
            # have knowledge of which platforms are incapable of dynamic linking, and
            # will still build on/for those platforms with --enable-shared, but simply
            # omit any `.so` build products such as libgcc_s.so.  When that happens,
            # it causes hard-to-troubleshoot build failures.
            hasSharedLibraries =
              !resolved.isStatic
              && (
                # Linux (allows multiple libcs)
                resolved.isAndroid
                || resolved.isGnu
                || resolved.isMusl
                # BSDs
                || resolved.isDarwin
                || resolved.isSunOS
                || resolved.isOpenBSD
                || resolved.isFreeBSD
                || resolved.isNetBSD
                # Windows
                || resolved.isCygwin
                || resolved.isMinGW
              );

            libc =
              if resolved.isDarwin
              then "libSystem"
              else if resolved.isMinGW
              then "msvcrt"
              else if resolved.isWasi
              then "wasilibc"
              else if resolved.isRedox
              then "relibc"
              else if resolved.isMusl
              then "musl"
              else if resolved.isUClibc
              then "uclibc"
              else if resolved.isAndroid
              then "bionic"
              else if resolved.isLinux
              then "glibc"
              else if resolved.isFreeBSD
              then "fblibc"
              else if resolved.isNetBSD
              then "nblibc"
              else if resolved.isAvr
              then "avrlibc"
              else if resolved.isGhcjs
              then null
              else if resolved.isNone
              then "newlib"
              else "native/impure";

            linker =
              if resolved.isDarwin
              then "cctools"
              else "bfd";

            extensions =
              (lib.attrs.when resolved.hasSharedLibraries {
                shared =
                  if resolved.isDarwin
                  then ".dylib"
                  else if resolved.isWindows
                  then ".dll"
                  else ".so";
              })
              // {
                static =
                  if resolved.isWindows
                  then ".lib"
                  else ".a";

                library =
                  if resolved.isStatic
                  then resolved.extensions.static
                  else resolved.extensions.shared;

                executable =
                  if resolved.isWindows
                  then ".exe"
                  else "";
              };

            uname = {
              system =
                if resolved.system.kernel.name == "linux"
                then "Linux"
                else if resolved.system.kernel.name == "windows"
                then "Windows"
                else if resolved.system.kernel.name == "darwin"
                then "Darwin"
                else if resolved.system.kernel.name == "netbsd"
                then "NetBSD"
                else if resolved.system.kernel.name == "freebsd"
                then "FreeBSD"
                else if resolved.system.kernel.name == "openbsd"
                then "OpenBSD"
                else if resolved.system.kernel.name == "wasi"
                then "Wasi"
                else if resolved.system.kernel.name == "redox"
                then "Redox"
                else if resolved.system.kernel.name == "redox"
                then "Genode"
                else null;

              processor =
                if resolved.isPower64
                then "ppc64${lib.strings.when resolved.isLittleEndian "le"}"
                else if resolved.isPower
                then "ppc${lib.strings.when resolved.isLittleEndian "le"}"
                else if resolved.isMips64
                then "mips64"
                else resolved.system.cpu.name;

              release = null;
            };

            useAndroidPrebuilt = false;
            useiOSPrebuilt = false;

            linux.arch =
              if resolved.isAarch32
              then "arm"
              else if resolved.isAarch64
              then "arm64"
              else if resolved.isx86_32
              then "i386"
              else if resolved.isx86_64
              then "x86_64"
              # linux kernel does not distinguish microblaze/microblazeel
              else if resolved.isMicroBlaze
              then "microblaze"
              else if resolved.isMips32
              then "mips"
              else if resolved.isMips64
              then "mips" # linux kernel does not distinguish mips32/mips64
              else if resolved.isPower
              then "powerpc"
              else if resolved.isRiscV
              then "riscv"
              else if resolved.isS390
              then "s390"
              else if resolved.isLoongArch64
              then "loongarch"
              else resolved.system.cpu.name;

            uboot.arch =
              if resolved.isx86_32
              then "x86" # not i386
              else if resolved.isMips64
              then "mips64" # uboot *does* distinguish between mips32/mips64
              else resolved.linuxArch; # other cases appear to agree with linuxArch

            qemu.arch =
              if resolved.isAarch32
              then "arm"
              else if resolved.isS390 && !resolved.isS390x
              then null
              else if resolved.isx86_64
              then "x86_64"
              else if resolved.isx86
              then "i386"
              else if resolved.isMips64n32
              then "mipsn32${lib.strings.when resolved.isLittleEndian "el"}"
              else if resolved.isMips64
              then "mips64${lib.strings.when resolved.isLittleEndian "el"}"
              else resolved.uname.processor;

            efi.arch =
              if resolved.isx86_32
              then "ia32"
              else if resolved.isx86_64
              then "x64"
              else if resolved.isAarch32
              then "arm"
              else if resolved.isAarch64
              then "aa64"
              else resolved.system.cpu.name;

            darwin = {
              arch =
                if resolved.system.cpu.name == "armv7a"
                then "armv7"
                else if resolved.system.cpu.name == "aarch64"
                then "arm64"
                else resolved.system.cpu.name;

              platform =
                if resolved.isMacOS
                then "macos"
                else if resolved.isiOS
                then "ios"
                else null;

              sdk = {
                version =
                  resolved.darwinSdkVersion
                  or (
                    if resolved.isAarch64
                    then "11.0"
                    else "10.12"
                  );

                min = resolved.darwin.sdk.version;

                variable =
                  if resolved.isMacOS
                  then "MACOSX_DEPLOYMENT_TARGET"
                  else if resolved.isiOS
                  then "IPHONEOS_DEPLOYMENT_TARGET"
                  else null;
              };
            };
          }
          // builtins.mapAttrs (name: match: match resolved.system) lib'.systems.match
          // builtins.mapAttrs (name: validate: validate (resolved.gcc.arch or "default")) lib'.systems.validate.architecture
          // settings;

        assertions =
          builtins.foldl'
          (
            result: {
              assertion,
              message,
            }:
              if assertion resolved
              then result
              else builtins.throw message
          )
          true
          (resolved.system.abi.assertions or []);
      in
        assert resolved.useAndroidPrebuilt -> resolved.isAndroid;
        assert assertions;
        # And finally, return the generated system info.
          resolved;
    };
  };
}
