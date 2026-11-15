#!/bin/sh
# Installs paginel-text (Paginel Text - CLI) from the releases of https://github.com/paginel/paginel-cli
#
#   curl -fsSL https://raw.githubusercontent.com/paginel/paginel-cli/main/install.sh | sh
#
# What it does: picks the archive of this system in SHA256SUMS.txt of the release, downloads it, checks its SHA-256
# (no checksum tool: it stops), installs paginel-text in ~/.local/bin (or PAGINEL_CLI_DEST), removes the macOS
# quarantine attribute, runs `paginel-text --version`. Nothing else is written; no root rights are needed.
# Run it again to update. Uninstall: delete the file it installed (rm ~/.local/bin/paginel-text).
#
# Environment (put it before `sh`: ... | PAGINEL_CLI_VERSION=0.3.0 sh):
#   PAGINEL_CLI_DEST      the folder to install into (default: ~/.local/bin)
#   PAGINEL_CLI_VERSION   a version such as 0.3.0 (default: the latest release); pin it in scripts and CI
#   PAGINEL_CLI_REPO      the GitHub repository (default: paginel/paginel-cli)
#
# Windows: install.ps1, in PowerShell:
#   irm https://raw.githubusercontent.com/paginel/paginel-cli/main/install.ps1 | iex
set -eu

REPO=${PAGINEL_CLI_REPO:-paginel/paginel-cli}
VERSION=${PAGINEL_CLI_VERSION:-latest}
DEST=${PAGINEL_CLI_DEST:-$HOME/.local/bin}

fail() { echo "paginel-text install: $*" >&2; exit 1; }
say() { echo "==> $*"; }

# ---- this system -------------------------------------------------------------------------------------------------------
os=$(uname -s)
arch=$(uname -m)
case "$os-$arch" in
    Darwin-arm64) TRIPLE=aarch64-apple-darwin ;;
    Darwin-x86_64)
        # A Terminal under Rosetta says x86_64 on an Apple silicon Mac.
        if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || true)" = 1 ]; then
            TRIPLE=aarch64-apple-darwin
        else
            fail "Intel Macs are not supported yet: paginel-text is built for Apple silicon only."
        fi ;;
    Linux-x86_64 | Linux-amd64) TRIPLE=x86_64-unknown-linux-gnu ;;
    Linux-*) fail "on Linux, only x86_64 is built for now (this machine: $arch)." ;;
    MINGW* | MSYS* | CYGWIN*) fail "on Windows, run this in PowerShell instead:
    irm https://raw.githubusercontent.com/$REPO/main/install.ps1 | iex" ;;
    *) fail "unsupported system: $os $arch." ;;
esac

if [ "$os" = Linux ]; then
    if ldd --version 2>&1 | grep -qi musl; then
        fail "this system uses musl (Alpine?): paginel-text needs glibc 2.35 or later (Debian 12, Ubuntu 22.04…)."
    fi
    glibc=$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}' || true)
    if [ -n "$glibc" ]; then
        major=${glibc%%.*}
        minor=${glibc#*.}
        minor=${minor%%.*}
        if [ "$major" -lt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -lt 35 ]; }; then
            fail "glibc $glibc is too old: paginel-text needs 2.35 or later (Ubuntu 22.04, Debian 12, Fedora 36…)."
        fi
    fi
fi

# ---- tools ----------------------------------------------------------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
    fetch() { curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
    fetch() { wget -q -O "$2" "$1"; }
else
    fail "this script needs curl or wget."
fi
if command -v sha256sum >/dev/null 2>&1; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
else
    fail "this script needs sha256sum or shasum to check the download."
fi
command -v tar >/dev/null 2>&1 || fail "this script needs tar."

WORK=$(mktemp -d "${TMPDIR:-/tmp}/paginel-text.XXXXXX")
trap 'rm -rf "$WORK"' EXIT INT TERM

# ---- download and check -----------------------------------------------------------------------------------------------
if [ "$VERSION" = latest ]; then
    BASE=https://github.com/$REPO/releases/latest/download
else
    BASE=https://github.com/$REPO/releases/download/v${VERSION#v}
fi
say "Release: $BASE"
fetch "$BASE/SHA256SUMS.txt" "$WORK/SHA256SUMS.txt" || fail "cannot download $BASE/SHA256SUMS.txt"

# The archive's name carries the version: read it from the list of checksums.
line=$(grep " paginel-text-[^ ]*-$TRIPLE\.tar\.gz\$" "$WORK/SHA256SUMS.txt" | head -1 || true)
if [ -z "$line" ]; then
    case "$TRIPLE" in
        *apple-darwin) fail "no macOS build in this release yet (Linux and Windows only); see https://github.com/$REPO" ;;
        *) fail "no archive for $TRIPLE in this release." ;;
    esac
fi
expected=$(echo "$line" | awk '{print $1}')
FILE=$(echo "$line" | awk '{print $2}' | sed 's/^\*//')
STEM=${FILE%.tar.gz}

say "Downloading $FILE"
fetch "$BASE/$FILE" "$WORK/$FILE" || fail "cannot download $BASE/$FILE"
got=$(sha256 "$WORK/$FILE")
[ "$got" = "$expected" ] || fail "$FILE: SHA-256 is $got, SHA256SUMS.txt says $expected. Nothing was installed."
say "SHA-256 checked"

tar -xzf "$WORK/$FILE" -C "$WORK"
[ -f "$WORK/$STEM/paginel-text" ] || fail "$FILE does not contain $STEM/paginel-text."

# ---- install ----------------------------------------------------------------------------------------------------------
mkdir -p "$DEST" || fail "cannot create $DEST (set PAGINEL_CLI_DEST to another folder)."
cp "$WORK/$STEM/paginel-text" "$DEST/.paginel-text.new"
chmod 755 "$DEST/.paginel-text.new"
mv -f "$DEST/.paginel-text.new" "$DEST/paginel-text"
if [ "$os" = Darwin ]; then
    xattr -d com.apple.quarantine "$DEST/paginel-text" 2>/dev/null || true
fi
installed=$("$DEST/paginel-text" --version 2>&1) || fail "$DEST/paginel-text does not run: $installed"
say "Installed: $DEST/paginel-text ($installed)"

case ":$PATH:" in
    *":$DEST:"*) ;;
    *)
        rc="$HOME/.bashrc"
        case "${SHELL:-}" in */zsh) rc="$HOME/.zshrc" ;; esac
        echo
        echo "$DEST is not on your PATH yet. Run this once, then open a new terminal:"
        echo "    echo 'export PATH=\"$DEST:\$PATH\"' >> $rc"
        echo "Until then: $DEST/paginel-text --help"
        ;;
esac
echo
echo "Next: paginel-text --help"
echo "Docs and examples: https://github.com/$REPO"
echo "Licence: free to use, proprietary (LICENSE in the archive, or https://github.com/$REPO/blob/main/LICENSE)."
