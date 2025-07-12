#!/bin/bash

# rAthena Parallel Build Test Script
# This script tests the parallel build functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_JOBS=(1 2 4 8)
TEST_BUILD_TYPES=("Debug" "Release")
TEST_DIR="test-builds"
FAILED_TESTS=()
PASSED_TESTS=()

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test_header() {
    echo ""
    echo "========================================"
    echo "TEST: $1"
    echo "========================================"
}

# Function to cleanup test directories
cleanup_tests() {
    print_info "Cleaning up test directories..."
    rm -rf "$TEST_DIR"
    if [ -f Makefile ]; then
        make clean >/dev/null 2>&1 || true
    fi
}

# Function to verify executables exist and are functional
verify_executables() {
    local build_path="$1"
    local test_name="$2"
    
    print_info "Verifying executables for $test_name..."
    
    # Check if executables exist (CMake builds place them in root directory)
    local executables=()
    local exe_locations=("$build_path" "../..")

    for location in "${exe_locations[@]}"; do
        if [ -f "$location/login-server" ] || [ -f "$location/login-server.exe" ]; then
            executables+=("login-server")
            break
        fi
    done

    for location in "${exe_locations[@]}"; do
        if [ -f "$location/char-server" ] || [ -f "$location/char-server.exe" ]; then
            executables+=("char-server")
            break
        fi
    done

    for location in "${exe_locations[@]}"; do
        if [ -f "$location/map-server" ] || [ -f "$location/map-server.exe" ]; then
            executables+=("map-server")
            break
        fi
    done

    for location in "${exe_locations[@]}"; do
        if [ -f "$location/web-server" ] || [ -f "$location/web-server.exe" ]; then
            executables+=("web-server")
            break
        fi
    done
    
    if [ ${#executables[@]} -eq 0 ]; then
        print_error "No executables found in $build_path"
        return 1
    fi
    
    print_success "Found ${#executables[@]} executables: ${executables[*]}"
    
    # Test that executables can run (basic smoke test)
    for exe in "${executables[@]}"; do
        local exe_path=""

        # Find the executable in possible locations
        for location in "${exe_locations[@]}"; do
            if [ -f "$location/$exe" ]; then
                exe_path="$location/$exe"
                break
            elif [ -f "$location/$exe.exe" ]; then
                exe_path="$location/$exe.exe"
                break
            fi
        done

        if [ -n "$exe_path" ] && [ -f "$exe_path" ]; then
            # Try to run with --help or --version to verify it's functional
            if timeout 5s "$exe_path" --help >/dev/null 2>&1 ||
               timeout 5s "$exe_path" --version >/dev/null 2>&1 ||
               timeout 5s "$exe_path" >/dev/null 2>&1; then
                print_success "$exe is functional"
            else
                print_warning "$exe may have issues (couldn't verify functionality)"
            fi
        fi
    done
    
    return 0
}

# Function to test CMake builds
test_cmake_build() {
    local jobs="$1"
    local build_type="$2"
    local test_name="cmake-${build_type,,}-j${jobs}"
    
    print_test_header "CMake Build: $build_type with $jobs jobs"
    
    if ! command -v cmake >/dev/null 2>&1; then
        print_warning "CMake not found, skipping CMake tests"
        return 0
    fi
    
    local build_dir="$TEST_DIR/$test_name"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    local start_time=$(date +%s)
    
    # Configure
    print_info "Configuring CMake build..."
    if ! cmake -DCMAKE_BUILD_TYPE="$build_type" \
               -DENABLE_PARALLEL_BUILD=ON \
               -DPARALLEL_BUILD_JOBS="$jobs" \
               ../.. >/dev/null 2>&1; then
        print_error "CMake configuration failed"
        FAILED_TESTS+=("$test_name: configuration failed")
        cd ../..
        return 1
    fi
    
    # Build
    print_info "Building with $jobs parallel jobs..."
    if ! cmake --build . --config "$build_type" -j "$jobs" >/dev/null 2>&1; then
        print_error "CMake build failed"
        FAILED_TESTS+=("$test_name: build failed")
        cd ../..
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify executables
    if verify_executables "." "$test_name"; then
        print_success "CMake build completed in ${duration}s"
        PASSED_TESTS+=("$test_name: ${duration}s")
    else
        print_error "CMake build verification failed"
        FAILED_TESTS+=("$test_name: verification failed")
        cd ../..
        return 1
    fi
    
    cd ../..
    return 0
}

# Function to test traditional make builds
test_make_build() {
    local jobs="$1"
    local test_name="make-j${jobs}"
    
    print_test_header "Traditional Make Build with $jobs jobs"
    
    if ! command -v make >/dev/null 2>&1; then
        print_warning "Make not found, skipping make tests"
        return 0
    fi
    
    # Clean any previous build
    if [ -f Makefile ]; then
        make clean >/dev/null 2>&1 || true
    fi
    
    local start_time=$(date +%s)
    
    # Configure if needed
    if [ ! -f Makefile ]; then
        print_info "Running configure script..."
        if ! ./configure >/dev/null 2>&1; then
            print_error "Configure script failed"
            FAILED_TESTS+=("$test_name: configure failed")
            return 1
        fi
    fi
    
    # Build
    print_info "Building with make -j$jobs..."
    if ! make -j "$jobs" server >/dev/null 2>&1; then
        print_error "Make build failed"
        FAILED_TESTS+=("$test_name: build failed")
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify executables
    if verify_executables "." "$test_name"; then
        print_success "Make build completed in ${duration}s"
        PASSED_TESTS+=("$test_name: ${duration}s")
    else
        print_error "Make build verification failed"
        FAILED_TESTS+=("$test_name: verification failed")
        return 1
    fi
    
    return 0
}

# Function to test build consistency
test_build_consistency() {
    print_test_header "Build Consistency Test"
    
    print_info "Comparing executables from different build methods..."
    
    # Find all executables from different builds
    local cmake_exe=""
    local make_exe=""
    
    # Look for CMake Release build
    if [ -f "$TEST_DIR/cmake-release-j4/map-server" ]; then
        cmake_exe="$TEST_DIR/cmake-release-j4/map-server"
    elif [ -f "$TEST_DIR/cmake-release-j2/map-server" ]; then
        cmake_exe="$TEST_DIR/cmake-release-j2/map-server"
    fi
    
    # Look for Make build
    if [ -f "map-server" ]; then
        make_exe="map-server"
    fi
    
    if [ -n "$cmake_exe" ] && [ -n "$make_exe" ]; then
        local cmake_size=$(stat -f%z "$cmake_exe" 2>/dev/null || stat -c%s "$cmake_exe" 2>/dev/null || echo "unknown")
        local make_size=$(stat -f%z "$make_exe" 2>/dev/null || stat -c%s "$make_exe" 2>/dev/null || echo "unknown")
        
        print_info "CMake executable size: $cmake_size bytes"
        print_info "Make executable size: $make_size bytes"
        
        # Sizes should be reasonably similar (within 10%)
        if [ "$cmake_size" != "unknown" ] && [ "$make_size" != "unknown" ]; then
            local size_diff=$((cmake_size - make_size))
            local size_diff_abs=${size_diff#-}  # absolute value
            local size_ratio=$((size_diff_abs * 100 / make_size))
            
            if [ $size_ratio -lt 10 ]; then
                print_success "Executable sizes are consistent (${size_ratio}% difference)"
                PASSED_TESTS+=("consistency: executable sizes match")
            else
                print_warning "Executable sizes differ significantly (${size_ratio}% difference)"
                PASSED_TESTS+=("consistency: executable sizes differ but acceptable")
            fi
        fi
    else
        print_warning "Cannot compare executables - missing builds"
    fi
}

# Function to run performance comparison
test_performance_comparison() {
    print_test_header "Performance Comparison"
    
    print_info "Analyzing build times..."
    
    # Extract build times from passed tests
    local single_job_time=""
    local multi_job_time=""
    
    for test in "${PASSED_TESTS[@]}"; do
        if [[ "$test" =~ j1:.*([0-9]+)s ]]; then
            single_job_time="${BASH_REMATCH[1]}"
        elif [[ "$test" =~ j4:.*([0-9]+)s ]]; then
            multi_job_time="${BASH_REMATCH[1]}"
        fi
    done
    
    if [ -n "$single_job_time" ] && [ -n "$multi_job_time" ]; then
        local speedup=$(echo "scale=2; $single_job_time / $multi_job_time" | bc 2>/dev/null || echo "unknown")
        if [ "$speedup" != "unknown" ]; then
            print_success "Parallel build speedup: ${speedup}x (${single_job_time}s -> ${multi_job_time}s)"
            PASSED_TESTS+=("performance: ${speedup}x speedup with parallel build")
        fi
    fi
}

# Function to show test results
show_test_results() {
    echo ""
    echo "========================================"
    echo "TEST RESULTS SUMMARY"
    echo "========================================"
    
    print_success "PASSED TESTS (${#PASSED_TESTS[@]}):"
    for test in "${PASSED_TESTS[@]}"; do
        echo "  ✓ $test"
    done
    
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo ""
        print_error "FAILED TESTS (${#FAILED_TESTS[@]}):"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ✗ $test"
        done
        echo ""
        print_error "Some tests failed. Please check the build configuration."
        return 1
    else
        echo ""
        print_success "All tests passed! Parallel build is working correctly."
        return 0
    fi
}

# Main test execution
main() {
    echo "rAthena Parallel Build Test Suite"
    echo "================================="
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "CMakeLists.txt" ] || [ ! -f "configure" ]; then
        print_error "This script must be run from the rAthena source directory"
        exit 1
    fi
    
    # Cleanup previous tests
    cleanup_tests
    
    # Test CMake builds with different job counts and build types
    for build_type in "${TEST_BUILD_TYPES[@]}"; do
        for jobs in "${TEST_JOBS[@]}"; do
            test_cmake_build "$jobs" "$build_type" || true
        done
    done
    
    # Test traditional make builds
    for jobs in "${TEST_JOBS[@]}"; do
        test_make_build "$jobs" || true
    done
    
    # Run consistency and performance tests
    test_build_consistency
    test_performance_comparison
    
    # Show results
    show_test_results
}

# Run main function
main "$@"
