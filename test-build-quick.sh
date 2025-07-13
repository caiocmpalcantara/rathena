#!/bin/bash

# Quick Build Test for rAthena Parallel Compilation
# This is a lightweight test to verify basic parallel build functionality

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Test configuration
QUICK_TEST_JOBS=4
TEST_BUILD_DIR="quick-test-build"

cleanup() {
    print_info "Cleaning up..."
    rm -rf "$TEST_BUILD_DIR"
    rm -f .rathena_config
    if [ -f Makefile ]; then
        make clean >/dev/null 2>&1 || true
    fi
    # Clean any executables
    rm -f login-server char-server map-server web-server
}

test_cmake_quick() {
    print_info "Testing CMake parallel build with separated workflow..."

    if ! command -v cmake >/dev/null 2>&1; then
        print_error "CMake not found"
        return 1
    fi

    # Check if new scripts exist
    if [ ! -f "configure" ] || [ ! -f "build.sh" ]; then
        print_error "New separated build scripts not found"
        return 1
    fi

    # Step 1: Configure for CMake
    if ! ./configure -t Release -d "$TEST_BUILD_DIR" >/dev/null 2>&1; then
        print_error "Configure step failed"
        return 1
    fi

    # Step 2: Build with the new build script
    if ! ./build.sh -j "$QUICK_TEST_JOBS" >/dev/null 2>&1; then
        print_error "Build step failed"
        return 1
    fi

    # Check if executables were created
    if [ -f "login-server" ] && [ -f "char-server" ] && [ -f "map-server" ]; then
        print_success "CMake separated workflow works"
        return 0
    else
        print_error "Executables not found after build"
        return 1
    fi
}

test_make_quick() {
    print_info "Testing Make parallel build with separated workflow..."

    if ! command -v make >/dev/null 2>&1; then
        print_error "Make not found"
        return 1
    fi

    # Check if new scripts exist
    if [ ! -f "configure" ] || [ ! -f "build.sh" ]; then
        print_error "New separated build scripts not found"
        return 1
    fi

    # Clean any previous configuration
    rm -f .rathena_config Makefile

    # Step 1: Configure for traditional make
    if ! ./configure -m >/dev/null 2>&1; then
        print_error "Configure step for make failed"
        return 1
    fi

    # Step 2: Build with the new build script
    if ! ./build.sh -j "$QUICK_TEST_JOBS" >/dev/null 2>&1; then
        print_error "Build step for make failed"
        return 1
    fi

    # Check if executables were created
    if [ -f "login-server" ] && [ -f "char-server" ] && [ -f "map-server" ]; then
        print_success "Make separated workflow works"
        return 0
    else
        print_error "Executables not found after make build"
        return 1
    fi
}

main() {
    echo "rAthena Quick Separated Build Workflow Test"
    echo "==========================================="

    if [ ! -f "CMakeLists.txt" ]; then
        print_error "Must run from rAthena source directory"
        exit 1
    fi

    # Check if new scripts exist
    if [ ! -f "configure" ]; then
        print_error "New configure script not found"
        exit 1
    fi

    if [ ! -f "build.sh" ]; then
        print_error "New build.sh not found"
        exit 1
    fi
    print_success "build.sh found"

    cleanup
    
    local cmake_result=0
    local make_result=0
    
    test_cmake_quick || cmake_result=1
    test_make_quick || make_result=1
    
    cleanup
    
    if [ $cmake_result -eq 0 ] && [ $make_result -eq 0 ]; then
        print_success "All quick tests passed!"
        exit 0
    else
        print_error "Some tests failed"
        exit 1
    fi
}

main "$@"
