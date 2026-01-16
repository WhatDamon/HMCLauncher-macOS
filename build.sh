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

mkdir -p "$DIST_DIR"

# Functions
print_step() {
    echo -e "${CYAN}==> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✖ $1${NC}"
}

# Build Steps

# Arm64 slice
print_step "Building arm64 slice..."
if swift build -c release --arch arm64 --build-path .build/arm64 \
    -Xswiftc -Osize -Xswiftc -whole-module-optimization; then
    print_success "arm64 build complete!"
else
    print_error "arm64 build failed!"
    exit 1
fi

# x86_64 slice
print_step "Building x86_64 slice..."
if swift build -c release --arch x86_64 --build-path .build/x86_64 \
    -Xswiftc -Osize -Xswiftc -whole-module-optimization; then
    print_success "x86_64 build complete!"
else
    print_error "x86_64 build failed!"
    exit 1
fi

# Combine into universal binary
print_step "Creating universal binary..."
ARM_BIN=".build/arm64/release/$BIN_NAME"
X64_BIN=".build/x86_64/release/$BIN_NAME"
UNIVERSAL_BIN="$DIST_DIR/$BIN_NAME"

if lipo -create "$ARM_BIN" "$X64_BIN" -output "$UNIVERSAL_BIN"; then
    print_success "Universal binary created!"
else
    print_error "Failed to create universal binary!"
    exit 1
fi

# Strip debug symbols
print_step "Stripping debug symbols for minimal size..."
strip -x "$UNIVERSAL_BIN"
print_success "Stripping complete!"

# Final Report
echo -e "${CYAN}Build complete!${NC}"
echo -e "${CYAN}Output file:${NC} $UNIVERSAL_BIN"
lipo -archs "$UNIVERSAL_BIN"
ls -lh "$UNIVERSAL_BIN"

# Optional clean-up warning
print_warning "Intermediate build files are in .build/ (can be removed if not needed)"