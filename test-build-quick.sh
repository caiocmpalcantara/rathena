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
    if [ -f Makefile ]; then
        make clean >/dev/null 2>&1 || true
    fi
}

test_cmake_quick() {
    print_info "Testing CMake parallel build..."
    
    if ! command -v cmake >/dev/null 2>&1; then
        print_error "CMake not found"
        return 1
    fi
    
    mkdir -p "$TEST_BUILD_DIR"
    cd "$TEST_BUILD_DIR"
    
    # Configure
    if ! cmake -DCMAKE_BUILD_TYPE=Release \
               -DENABLE_PARALLEL_BUILD=ON \
               -DPARALLEL_BUILD_JOBS="$QUICK_TEST_JOBS" \
               .. >/dev/null 2>&1; then
        print_error "CMake configuration failed"
        cd ..
        return 1
    fi
    
    # Build just the common library (fastest test)
    if ! cmake --build . --target common -j "$QUICK_TEST_JOBS" >/dev/null 2>&1; then
        print_error "CMake build failed"
        cd ..
        return 1
    fi
    
    print_success "CMake parallel build works"
    cd ..
    return 0
}

test_make_quick() {
    print_info "Testing Make parallel build..."
    
    if ! command -v make >/dev/null 2>&1; then
        print_error "Make not found"
        return 1
    fi
    
    # Configure if needed
    if [ ! -f Makefile ]; then
        if ! ./configure >/dev/null 2>&1; then
            print_error "Configure failed"
            return 1
        fi
    fi
    
    # Build just the common target
    if ! make -j "$QUICK_TEST_JOBS" common >/dev/null 2>&1; then
        print_error "Make parallel build failed"
        return 1
    fi
    
    print_success "Make parallel build works"
    return 0
}

main() {
    echo "rAthena Quick Parallel Build Test"
    echo "================================="
    
    if [ ! -f "CMakeLists.txt" ]; then
        print_error "Must run from rAthena source directory"
        exit 1
    fi
    
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
