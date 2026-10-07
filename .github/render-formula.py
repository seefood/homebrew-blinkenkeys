#!/usr/bin/env python3
"""Render the formula template: render-formula.py TEMPLATE SHA256SUMS VERSION OUT

Fills VERSION and one SHA256_<OS>_<ARCH> per release tarball listed in
SHA256SUMS, and fails if any placeholder is left unfilled or a tarball in the
template has no checksum.
"""
import re
import sys

template, sums, version, out = sys.argv[1:5]
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    sys.exit(f"bad version {version!r}")

text = open(template).read()
filled = text.replace('ver = "VERSION"', f'ver = "{version}"')

for line in open(sums):
    digest, name = line.split()
    m = re.fullmatch(rf"blinkenkeys-v{re.escape(version)}-(\w+)-(\w+)\.tar\.gz", name)
    if m:
        filled = filled.replace(f"SHA256_{m[1].upper()}_{m[2].upper()}", digest)

left = re.findall(r'"VERSION"|SHA256_[A-Z0-9_]+', filled)
if left:
    sys.exit(f"unfilled placeholders: {sorted(set(left))}")
open(out, "w").write(filled)
