#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BIN_NAME="HMCLauncher"
DIST_DIR="dist"

RUN_TESTS=true
STRIP_BINARY=true
TARGET_ARCH="universal"

mkdir -p "$DIST_DIR/arm64" "$DIST_DIR/x86_64"

# Functions
step() { echo -e "${CYAN}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}! $1${NC}"; }
fail() { echo -e "${RED}✖ $1${NC}"; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h, --help            Show this help message and exit
  -t, --bypass-tests    Skip running tests
  -s, --no-strip        Do not strip the final binary
  -a, --arch <arch>     Build single architecture (arm64 | x86_64)
EOF
}

# Argument Parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -t|--bypass-tests)
      RUN_TESTS=false
      ;;
    -s|--no-strip)
      STRIP_BINARY=false
      ;;
    -a|--arch)
      [[ $# -ge 2 ]] || fail "--arch requires a value"
      TARGET_ARCH="$2"
      shift
      ;;
    *)
      fail "Unknown argument: $1 (use --help)"
      ;;
  esac
  shift
done

# Tests
if $RUN_TESTS; then
  step "Running tests..."
  swift test || fail "Tests failed. Aborting build."
  ok "All tests passed!"
else
  warn "Tests bypassed"
fi

# Build Function
build_arch() {
  local arch="$1"
  step "Building $arch slice..."
  swift build -c release --arch "$arch" --build-path ".build/$arch" \
    -Xswiftc -Osize \
    -Xswiftc -whole-module-optimization
  ok "$arch build complete!"
}

# Build
case "$TARGET_ARCH" in
  arm64|x86_64)
    build_arch "$TARGET_ARCH"
    cp ".build/$TARGET_ARCH/release/$BIN_NAME" \
        "$DIST_DIR/$TARGET_ARCH/$BIN_NAME"
    FINAL_BIN="$DIST_DIR/$TARGET_ARCH/$BIN_NAME"
    ;;
  universal)
    build_arch arm64
    build_arch x86_64
    step "Creating universal binary..."
    lipo -create \
        "$DIST_DIR/arm64/$BIN_NAME" \
        "$DIST_DIR/x86_64/$BIN_NAME" \
        -output "$DIST_DIR/$BIN_NAME"
    ok "Universal binary created!"
    FINAL_BIN="$DIST_DIR/$BIN_NAME"
    ;;
  *)
    fail "Invalid architecture: $TARGET_ARCH"
    ;;
esac

# Strip
if $STRIP_BINARY; then
  step "Stripping symbols..."
  strip -x "$FINAL_BIN"
  ok "Stripping complete!"
else
  warn "Stripping skipped"
fi

# Report
step "Build complete"
echo "Binary: $FINAL_BIN"
lipo -archs "$FINAL_BIN" 2>/dev/null || true
ls -lh "$FINAL_BIN"

warn "Intermediate files remain in .build/ (safe to remove)"