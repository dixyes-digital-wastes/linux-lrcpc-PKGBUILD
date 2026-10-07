# linux-lrcpc: the Arch package

An Arch package for a kernel with **emulation of the RCpc acquire loads and the
LSE atomic instructions built in**. On an arm64 machine that has neither
FEAT_LRCPC nor FEAT_LSE, the instructions a userspace built for a newer baseline
contains are carried out by the kernel instead of raising SIGILL.

The package is called `linux-lrcpc`, so it installs **alongside** the stock
kernel rather than replacing it.

The kernel, the emulation and the patch series come from
<https://github.com/dixyes-digital-wastes/linux/tree/lse-emul>; the patches in
this repository are those five commits backported onto the 7.2 series, which is
what the userspace kernel is based on.

## License

Two licenses, and it is worth not mixing them up:

* **The packaging** -- this PKGBUILD and the helper scripts -- is under the
  **ISC** license of the upstream packaging repository it is derived from:
  `LICENSE` is that file, `Copyright Arch Linux Contributors`, kept verbatim,
  and the upstream maintainer's line stays at the top of the PKGBUILD. The
  helper scripts carry `SPDX-License-Identifier: ISC`.
* **The kernel it packages** is **GPL-2.0-only**, which is what the PKGBUILD's
  `license=(GPL-2.0-only)` declares and what the kernel's own files say in their
  SPDX lines. The patch series and `config.aarch64` are kernel code, so they
  stay `GPL-2.0-only`; nothing here relicenses them.
