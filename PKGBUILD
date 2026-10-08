# Maintainer: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Contributor: Yun Dou <dixyes@gmail.com>
#
# linux-lrcpc: the distribution's own linux PKGBUILD, pointed at the tree that
# carries the RCpc and LSE instruction emulation
#
# base: https://gitlab.archlinux.org/archlinux/packaging/packages/linux
#       PKGBUILD of linux 7.2.9.arch1-1 (the version the aarch64 repository
#       this userspace came from ships). That repository is under the ISC
#       license (LICENSE here, Copyright Arch Linux Contributors, unchanged);
#       the kernel this packages stays GPL-2.0-only, and so do the patch series
#       and the config taken from it
#
# What was changed, and nothing else:
#
#   * pkgbase is linux-lrcpc, so this can be installed next to the stock kernel
#     instead of replacing it; the main package and the headers package (which
#     is what DKMS needs) are built, and -docs is not
#   * arch is aarch64, the source is the kernel.org tarball of the release the
#     distribution's kernel is based on, and the emulation comes in as the
#     patch series (patch-000*.patch) instead of the Arch patch set
#   * config.aarch64 is the config of the distribution's own linux package,
#     extracted from its vmlinuz with scripts/extract-ikconfig; three settings
#     are turned on below, the hns3 driver is on as a module (the PCIe NIC of
#     the machine this is for), and DEBUG_INFO is turned off there to keep the
#     build short -- that last one is the only deviation with no runtime
#     meaning, and the DEBUG_INFO choice is one olddefconfig makes again
#   * a cross build sets CROSS_COMPILE, since this is usually built on an
#     x86_64 box; on an aarch64 box it builds natively
#   * htmldocs and the bpftool header generation are dropped along with the
#     packages that wanted them
#
pkgbase=linux-lrcpc
pkgver=7.2.9
pkgrel=3
pkgdesc='Linux with RCpc and LSE instruction emulation for CPUs without them'
url='https://github.com/dixyes-digital-wastes/linux'
arch=(
  aarch64
)
license=(GPL-2.0-only)
makedepends=(
  bc
  binutils
  cpio
  gettext
  glibc
  libelf
  libgcc
  openssl
  pahole
  perl
  python
  tar
  xxhash
  xz
  zlib
  zstd
)
options=(
  !debug
  !strip
)
_srcname=linux-7.2.9
source=(
  https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/${_srcname}.tar.{xz,sign}
  patch-0001-RCpc-loads.patch
  patch-0002-RCpc-rewrite.patch
  patch-0003-shared-primitives.patch
  patch-0004-LSE-emulation.patch
  patch-0005-LSE-blocks.patch
  patch-0006-stale-fetch.patch
  patch-0007-mmap-lock.patch
  patch-0008-block-hook.patch
  config.aarch64
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
)
sha256sums=('b4c5dfbe51a364a6c7f03869200f88c8e1f77403539005f14b7fc6bc91b8d8ba'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP')

export KBUILD_BUILD_HOST=archlinux
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

# the three switches this kernel exists for; the emulation is built in, so it
# is on for every task the moment the kernel boots
_emulation=(ARM64_UNDEF_EMULATION ARM64_RCPC_EMULATION ARM64_LSE_EMULATION)

if [[ $CARCH != "$(uname -m)" ]]; then
  export ARCH=arm64
  export CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-}
else
  export ARCH=arm64
fi

prepare() {
  cd $_srcname

  echo "Setting version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${pkgbase#linux}" > localversion.20-pkgname

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    src="${src%.zst}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done

  echo "Setting config..."
  cp ../config.aarch64 .config
  local one
  for one in "${_emulation[@]}"; do
    scripts/config --file .config -e "$one"
  done
  scripts/config --file .config -d DEBUG_INFO -e DEBUG_INFO_NONE -d DEBUG_INFO_BTF
  make olddefconfig
  diff -u ../config.aarch64 .config || :

  for one in "${_emulation[@]}"; do
    if [[ $(scripts/config --file .config -s $one) != y ]]; then
      echo "$one did not come out enabled" >&2
      exit 1
    fi
  done

  make -s kernelrelease > version
  echo "Prepared $pkgbase version $(<version)"
}

build() {
  cd $_srcname

  make all
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=(
    coreutils
    initramfs
    kmod
  )
  optdepends=(
    'linux-firmware: firmware images needed for some devices'
    'wireless-regdb: to set the correct wireless channels of your country'
  )

  cd $_srcname
  local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

  echo "Installing boot image..."
  # systemd expects to find the kernel here to allow hibernation
  install -Dm644 arch/arm64/boot/Image "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing config..."
  install -Dm644 .config "$pkgdir/boot/config-$pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist modules_install  # Suppress depmod

  # remove build link
  rm "$modulesdir"/build
}

_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=(
    binutils
    glibc
    libelf
    libgcc
    openssl
    pahole
    xxhash
    zlib
    zstd
  )
  provides=(
    LINUX-HEADERS
  )

  cd $_srcname
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"
  local karch=arm64

  echo "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/$karch" -m644 arch/$karch/Makefile
  cp -t "$builddir" -a scripts
  ln -srt "$builddir" "$builddir/scripts/gdb/vmlinux-gdb.py"

  echo "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/$karch" -a arch/$karch/include
  install -Dt "$builddir/arch/$karch/kernel" -m644 arch/$karch/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  echo "Installing unstripped VDSO..."
  make INSTALL_MOD_PATH="$pkgdir/usr" vdso_install \
    link=  # Suppress build-id symlinks

  echo "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */$karch/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  echo "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  echo "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -Sib "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v $STRIP_SHARED "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v $STRIP_STATIC "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v $STRIP_BINARIES "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  echo "Stripping vmlinux..."
  strip -v $STRIP_STATIC "$builddir/vmlinux"

  echo "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

pkgname=(
  "$pkgbase"
  "$pkgbase-headers"
)
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
  }"
done

# vim:set ts=8 sts=2 sw=2 et:
