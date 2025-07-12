#!/bin/bash

# rAthena Enhanced Parallel Build Configuration Script
# This script integrates parallel build optimization with rAthena's configure options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="Release"
BUILD_DIR="build"
JOBS=0  # 0 = auto-detect
CLEAN=false
INSTALL=false
USE_CMAKE=true
VERBOSE=false
CONFIGURE_ARGS=""

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

# Function to show usage
show_usage() {
    cat << EOF
rAthena Enhanced Parallel Build Configuration Script

Usage: $0 [PARALLEL_OPTIONS] [-- CONFIGURE_OPTIONS]

PARALLEL OPTIONS:
    -j, --jobs NUM          Number of parallel jobs (default: auto-detect)
    -t, --type TYPE         Build type: Debug, Release, RelWithDebInfo (default: Release)
    -d, --dir DIR           Build directory (default: build)
    -c, --clean             Clean build directory before building
    -i, --install           Install after building
    -m, --make              Use traditional make instead of CMake
    -v, --verbose           Verbose output
    -h, --help              Show this help message

CONFIGURE OPTIONS (passed to ./configure):
    All standard rAthena configure options are supported after '--'
    
    Common rAthena options:
    --enable-packetver=VER  Set packet version (e.g., 20180620, 20200401)
    --enable-prere          Enable pre-renewal mode
    --enable-renewal        Enable renewal mode (default)
    --enable-debug          Enable debug mode
    --enable-vip            Enable VIP features
    --enable-warn           Enable compiler warnings
    --with-mysql=PATH       MySQL installation path
    --with-pcre=PATH        PCRE library path
    --with-zlib=PATH        Zlib library path
    --with-maxconn=NUM      Maximum connections

EXAMPLES:
    # Basic parallel build with auto-detection
    $0

    # 8 parallel jobs with default settings
    $0 -j 8

    # Pre-renewal mode with specific packet version
    $0 -j 16 -- --enable-prere --enable-packetver=20180620

    # Debug build with VIP features
    $0 -j 8 -t Debug -- --enable-debug --enable-vip

    # Traditional make with renewal and custom MySQL
    $0 -m -j 12 -- --enable-renewal --with-mysql=/usr/local/mysql

    # Clean build with warnings enabled
    $0 -c -j 8 -- --enable-warn --enable-debug

EOF
}

# Function to detect number of CPU cores
detect_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif [ -f /proc/cpuinfo ]; then
        grep -c ^processor /proc/cpuinfo
    elif command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.ncpu 2>/dev/null || echo 4
    else
        echo 4
    fi
}

# Function to parse arguments
parse_arguments() {
    local configure_mode=false
    
    while [[ $# -gt 0 ]]; do
        if [ "$configure_mode" = true ]; then
            # Everything after -- goes to configure
            CONFIGURE_ARGS="$CONFIGURE_ARGS $1"
            shift
            continue
        fi
        
        case $1 in
            -j|--jobs)
                JOBS="$2"
                shift 2
                ;;
            -t|--type)
                BUILD_TYPE="$2"
                shift 2
                ;;
            -d|--dir)
                BUILD_DIR="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -i|--install)
                INSTALL=true
                shift
                ;;
            -m|--make)
                USE_CMAKE=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --)
                configure_mode=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function to validate and setup build configuration
setup_build_config() {
    # Auto-detect cores if not specified
    if [ "$JOBS" -eq 0 ]; then
        JOBS=$(detect_cores)
        print_info "Auto-detected $JOBS CPU cores"
    else
        print_info "Using $JOBS parallel jobs"
    fi
    
    # Validate build type
    case $BUILD_TYPE in
        Debug|Release|RelWithDebInfo|MinSizeRel)
            ;;
        *)
            print_error "Invalid build type: $BUILD_TYPE"
            print_info "Valid types: Debug, Release, RelWithDebInfo, MinSizeRel"
            exit 1
            ;;
    esac
    
    print_info "Build configuration:"
    print_info "  Build system: $([ "$USE_CMAKE" = true ] && echo "CMake" || echo "Traditional Make")"
    print_info "  Build type: $BUILD_TYPE"
    print_info "  Build directory: $BUILD_DIR"
    print_info "  Parallel jobs: $JOBS"
    print_info "  Configure args: ${CONFIGURE_ARGS:-"(default)"}"
    print_info "  Clean build: $CLEAN"
    print_info "  Install: $INSTALL"
}

# Function to run configure with arguments
run_configure() {
    if [ -n "$CONFIGURE_ARGS" ]; then
        print_info "Running configure with custom options: $CONFIGURE_ARGS"
        if [ "$VERBOSE" = true ]; then
            ./configure $CONFIGURE_ARGS
        else
            ./configure $CONFIGURE_ARGS >/dev/null 2>&1
        fi
    else
        print_info "Running configure with default options"
        if [ "$VERBOSE" = true ]; then
            ./configure
        else
            ./configure >/dev/null 2>&1
        fi
    fi
}

# Function to translate configure arguments to CMake arguments
translate_configure_to_cmake() {
    local cmake_args=()

    if [ -n "$CONFIGURE_ARGS" ]; then
        print_info "Translating configure arguments to CMake options..."

        # Parse configure arguments
        for arg in $CONFIGURE_ARGS; do
            case $arg in
                --enable-prere|--enable-prere=yes)
                    cmake_args+=(-DENABLE_PRERE=ON)
                    cmake_args+=(-DENABLE_RENEWAL=OFF)
                    print_info "  Translated: $arg -> -DENABLE_PRERE=ON -DENABLE_RENEWAL=OFF"
                    ;;
                --disable-prere|--enable-prere=no)
                    cmake_args+=(-DENABLE_PRERE=OFF)
                    ;;
                --enable-renewal|--enable-renewal=yes)
                    cmake_args+=(-DENABLE_RENEWAL=ON)
                    cmake_args+=(-DENABLE_PRERE=OFF)
                    print_info "  Translated: $arg -> -DENABLE_RENEWAL=ON -DENABLE_PRERE=OFF"
                    ;;
                --disable-renewal|--enable-renewal=no)
                    cmake_args+=(-DENABLE_RENEWAL=OFF)
                    ;;
                --enable-packetver=*)
                    local packetver="${arg#*=}"
                    cmake_args+=(-DPACKETVER="$packetver")
                    print_info "  Translated: $arg -> -DPACKETVER=$packetver"
                    ;;
                --enable-debug|--enable-debug=yes)
                    cmake_args+=(-DENABLE_DEBUG=ON)
                    print_info "  Translated: $arg -> -DENABLE_DEBUG=ON"
                    ;;
                --disable-debug|--enable-debug=no)
                    cmake_args+=(-DENABLE_DEBUG=OFF)
                    ;;
                --enable-vip|--enable-vip=yes)
                    cmake_args+=(-DENABLE_VIP=ON)
                    print_info "  Translated: $arg -> -DENABLE_VIP=ON"
                    ;;
                --disable-vip|--enable-vip=no)
                    cmake_args+=(-DENABLE_VIP=OFF)
                    ;;
                --enable-warn|--enable-warn=yes)
                    cmake_args+=(-DENABLE_WARN=ON)
                    print_info "  Translated: $arg -> -DENABLE_WARN=ON"
                    ;;
                --disable-warn|--enable-warn=no)
                    cmake_args+=(-DENABLE_WARN=OFF)
                    ;;
                --enable-epoll|--enable-epoll=yes)
                    cmake_args+=(-DENABLE_EPOLL=ON)
                    print_info "  Translated: $arg -> -DENABLE_EPOLL=ON"
                    ;;
                --disable-epoll|--enable-epoll=no)
                    cmake_args+=(-DENABLE_EPOLL=OFF)
                    ;;
                --enable-rdtsc|--enable-rdtsc=yes)
                    cmake_args+=(-DENABLE_RDTSC=ON)
                    print_info "  Translated: $arg -> -DENABLE_RDTSC=ON"
                    ;;
                --disable-rdtsc|--enable-rdtsc=no)
                    cmake_args+=(-DENABLE_RDTSC=OFF)
                    ;;
                --enable-buildbot|--enable-buildbot=yes)
                    cmake_args+=(-DENABLE_EXTRA_BUILDBOT_CODE=ON)
                    print_info "  Translated: $arg -> -DENABLE_EXTRA_BUILDBOT_CODE=ON"
                    ;;
                --disable-buildbot|--enable-buildbot=no)
                    cmake_args+=(-DENABLE_EXTRA_BUILDBOT_CODE=OFF)
                    ;;
                --with-maxconn=*)
                    local maxconn="${arg#*=}"
                    cmake_args+=(-DMAXCONN="$maxconn")
                    print_info "  Translated: $arg -> -DMAXCONN=$maxconn"
                    ;;
                --with-outputlogin=*)
                    local output="${arg#*=}"
                    cmake_args+=(-DOUTPUT_LOGIN="$output")
                    print_info "  Translated: $arg -> -DOUTPUT_LOGIN=$output"
                    ;;
                --with-outputchar=*)
                    local output="${arg#*=}"
                    cmake_args+=(-DOUTPUT_CHAR="$output")
                    print_info "  Translated: $arg -> -DOUTPUT_CHAR=$output"
                    ;;
                --with-outputmap=*)
                    local output="${arg#*=}"
                    cmake_args+=(-DOUTPUT_MAP="$output")
                    print_info "  Translated: $arg -> -DOUTPUT_MAP=$output"
                    ;;
                --with-outputweb=*)
                    local output="${arg#*=}"
                    cmake_args+=(-DOUTPUT_WEB="$output")
                    print_info "  Translated: $arg -> -DOUTPUT_WEB=$output"
                    ;;
                --enable-profiler=*)
                    local profiler="${arg#*=}"
                    cmake_args+=(-DENABLE_PROFILER="$profiler")
                    print_info "  Translated: $arg -> -DENABLE_PROFILER=$profiler"
                    ;;
                --enable-manager=*)
                    local manager="${arg#*=}"
                    cmake_args+=(-DENABLE_MEMMGR="$manager")
                    print_info "  Translated: $arg -> -DENABLE_MEMMGR=$manager"
                    ;;
                --with-mysql=*|--with-pcre=*|--with-zlib=*)
                    print_warning "  Library path option $arg not directly translatable to CMake"
                    print_warning "  CMake will use system package detection instead"
                    ;;
                *)
                    print_warning "  Unknown configure option: $arg (ignored)"
                    ;;
            esac
        done
    fi

    # Return the translated arguments
    echo "${cmake_args[@]}"
}

# Function to build with CMake
build_cmake() {
    print_info "Starting CMake build..."

    # Clean build directory if requested
    if [ "$CLEAN" = true ]; then
        print_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
    fi

    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Configure CMake
    print_info "Configuring with CMake..."
    CMAKE_ARGS=(
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
        -DENABLE_PARALLEL_BUILD=ON
        -DPARALLEL_BUILD_JOBS="$JOBS"
    )

    if [ "$VERBOSE" = true ]; then
        CMAKE_ARGS+=(-DCMAKE_VERBOSE_MAKEFILE=ON)
    fi

    # Translate configure arguments to CMake arguments
    if [ -n "$CONFIGURE_ARGS" ]; then
        print_info "Translating configure arguments for CMake build..."
        # Parse configure arguments directly into CMAKE_ARGS
        for arg in $CONFIGURE_ARGS; do
            case $arg in
                --enable-prere|--enable-prere=yes)
                    CMAKE_ARGS+=(-DENABLE_PRERE=ON)
                    CMAKE_ARGS+=(-DENABLE_RENEWAL=OFF)
                    print_info "  Translated: $arg -> -DENABLE_PRERE=ON -DENABLE_RENEWAL=OFF"
                    ;;
                --enable-renewal|--enable-renewal=yes)
                    CMAKE_ARGS+=(-DENABLE_RENEWAL=ON)
                    CMAKE_ARGS+=(-DENABLE_PRERE=OFF)
                    print_info "  Translated: $arg -> -DENABLE_RENEWAL=ON -DENABLE_PRERE=OFF"
                    ;;
                --enable-packetver=*)
                    local packetver="${arg#*=}"
                    CMAKE_ARGS+=(-DPACKETVER="$packetver")
                    print_info "  Translated: $arg -> -DPACKETVER=$packetver"
                    ;;
                --enable-debug|--enable-debug=yes)
                    CMAKE_ARGS+=(-DENABLE_DEBUG=ON)
                    print_info "  Translated: $arg -> -DENABLE_DEBUG=ON"
                    ;;
                --enable-vip|--enable-vip=yes)
                    CMAKE_ARGS+=(-DENABLE_VIP=ON)
                    print_info "  Translated: $arg -> -DENABLE_VIP=ON"
                    ;;
                --enable-warn|--enable-warn=yes)
                    CMAKE_ARGS+=(-DENABLE_WARN=ON)
                    print_info "  Translated: $arg -> -DENABLE_WARN=ON"
                    ;;
                --enable-epoll|--enable-epoll=yes)
                    CMAKE_ARGS+=(-DENABLE_EPOLL=ON)
                    print_info "  Translated: $arg -> -DENABLE_EPOLL=ON"
                    ;;
                --with-maxconn=*)
                    local maxconn="${arg#*=}"
                    CMAKE_ARGS+=(-DMAXCONN="$maxconn")
                    print_info "  Translated: $arg -> -DMAXCONN=$maxconn"
                    ;;
                --with-mysql=*|--with-pcre=*|--with-zlib=*)
                    print_warning "  Library path option $arg not directly translatable to CMake"
                    ;;
                *)
                    print_warning "  Unknown configure option: $arg (ignored)"
                    ;;
            esac
        done
    fi

    cmake "${CMAKE_ARGS[@]}" ..

    # Build
    print_info "Building with $JOBS parallel jobs..."
    BUILD_ARGS=(--build . --config "$BUILD_TYPE" -j "$JOBS")

    if [ "$VERBOSE" = true ]; then
        BUILD_ARGS+=(--verbose)
    fi

    cmake "${BUILD_ARGS[@]}"

    # Install if requested
    if [ "$INSTALL" = true ]; then
        print_info "Installing..."
        cmake --install . --config "$BUILD_TYPE"
    fi

    cd ..
}

# Function to build with traditional make
build_make() {
    print_info "Starting traditional make build..."
    
    # Clean if requested
    if [ "$CLEAN" = true ]; then
        print_info "Cleaning previous build..."
        if [ -f Makefile ]; then
            make clean >/dev/null 2>&1 || true
        fi
    fi
    
    # Run configure
    print_info "Configuring build system..."
    run_configure
    
    # Build with parallel jobs
    print_info "Building with make -j$JOBS..."
    MAKE_ARGS=(-j "$JOBS")
    
    if [ "$VERBOSE" = true ]; then
        MAKE_ARGS+=(V=1)
    fi
    
    make "${MAKE_ARGS[@]}" server
    
    # Install if requested
    if [ "$INSTALL" = true ]; then
        print_info "Installing..."
        make install
    fi
}

# Main execution
main() {
    echo "rAthena Enhanced Parallel Build Configuration"
    echo "============================================="
    echo ""
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Setup build configuration
    setup_build_config
    echo ""
    
    # Check if we're in the rAthena source directory
    if [ ! -f "CMakeLists.txt" ] || [ ! -f "configure" ]; then
        print_error "This script must be run from the rAthena source directory"
        exit 1
    fi
    
    # Build based on selected system
    if [ "$USE_CMAKE" = true ]; then
        build_cmake
    else
        build_make
    fi
    
    print_success "Build completed successfully!"
    
    if [ "$USE_CMAKE" = true ]; then
        print_info "Executables are in: $BUILD_DIR/ and root directory"
    else
        print_info "Executables are in the source directory"
    fi
    
    print_info ""
    print_info "To use parallel builds in the future:"
    if [ "$USE_CMAKE" = true ]; then
        print_info "  cmake --build $BUILD_DIR -j$JOBS"
    else
        print_info "  make -j$JOBS server"
    fi
}

# Run main function
main "$@"
