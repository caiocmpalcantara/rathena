# Parallel Build Troubleshooting Guide

This guide helps resolve common issues with rAthena's parallel build system.

## Quick Diagnostics

Run these commands to quickly identify issues:

```bash
# Quick verification
./test-build-quick.sh

# System information
./configure-parallel.sh

# Comprehensive testing
./test-parallel-build.sh
```

## Common Issues

### 1. Build Fails with High Job Count

**Symptoms:**
- Build works with `-j1` or `-j2` but fails with `-j8` or higher
- "virtual memory exhausted" errors
- System becomes unresponsive during build

**Causes:**
- Insufficient RAM for parallel compilation
- Too many parallel jobs for system capacity

**Solutions:**

```bash
# Check available memory
free -h

# Use fewer jobs based on memory
# Rule: 1GB RAM per job for C++ compilation
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
SAFE_JOBS=$((MEMORY_GB - 1))  # Leave 1GB for system
echo "Safe job count: $SAFE_JOBS"

# Build with safe job count
make -j$SAFE_JOBS server
```

### 2. Linker Errors in Parallel Build

**Symptoms:**
- Compilation succeeds but linking fails
- "undefined reference" errors
- Works with sequential build (`-j1`)

**Causes:**
- Race conditions in dependency resolution
- Incorrect makefile dependencies

**Solutions:**

```bash
# Clean and rebuild
make clean
make -j4 server

# For CMake builds
rm -rf build
mkdir build && cd build
cmake -DENABLE_PARALLEL_BUILD=ON ..
cmake --build . -j4
```

### 3. "make: command not found"

**Symptoms:**
- `make` command not available
- Build scripts fail

**Solutions:**

```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# CentOS/RHEL
sudo yum groupinstall "Development Tools"

# macOS
xcode-select --install
# or install via Homebrew
brew install make
```

### 4. CMake Configuration Fails

**Symptoms:**
- CMake cannot find dependencies
- Configuration errors with parallel build options
- Regex compilation errors like: `RegularExpression::compile(): Nested *?+.`

**Solutions:**

```bash
# Check CMake version (need 3.13+)
cmake --version

# Update CMake if needed
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install cmake

# Clear CMake cache
rm -rf CMakeCache.txt CMakeFiles/

# Reconfigure
cmake -DENABLE_PARALLEL_BUILD=ON ..
```

**Note:** The regex compilation error in rapidyaml has been fixed in the current implementation. This was caused by special characters in file paths being interpreted as regex metacharacters.

### 5. Slow Parallel Builds

**Symptoms:**
- Parallel build not much faster than sequential
- CPU usage low during compilation

**Causes:**
- I/O bottleneck (slow storage)
- Incorrect dependency graph
- Insufficient parallelization

**Solutions:**

```bash
# Check I/O usage during build
iostat -x 1  # Linux
# Look for high %util values

# Use faster storage if available
# Move source to SSD if on HDD

# Check CPU usage
htop  # Should see high CPU usage across cores

# Try different job counts
for jobs in 2 4 8 16; do
    echo "Testing with $jobs jobs..."
    time make -j$jobs clean server
done
```

### 6. Permission Errors

**Symptoms:**
- "Permission denied" errors
- Cannot create directories

**Solutions:**

```bash
# Check file permissions
ls -la

# Fix script permissions
chmod +x build-parallel.sh
chmod +x configure-parallel.sh
chmod +x test-*.sh

# Ensure write permissions in build directory
chmod -R u+w .
```

### 7. Windows-Specific Issues

**Symptoms:**
- Build fails on Windows with MSYS2/MinGW
- Path-related errors

**Solutions:**

```bash
# Use Windows-style paths in MSYS2
export MSYSTEM=MINGW64

# Use Windows job detection
JOBS=$(nproc)
make -j$JOBS server

# For Visual Studio builds
cmake -G "Visual Studio 16 2019" -DENABLE_PARALLEL_BUILD=ON ..
cmake --build . --config Release -j 8
```

## Performance Optimization

### Memory Optimization

```bash
# Monitor memory usage during build
watch -n 1 'free -h'

# Adjust job count based on memory pressure
# If swap usage increases, reduce jobs

# Add swap space if needed (Linux)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Storage Optimization

```bash
# Use tmpfs for builds (if enough RAM)
sudo mount -t tmpfs -o size=4G tmpfs /tmp/rathena-build
cp -r . /tmp/rathena-build/
cd /tmp/rathena-build/

# Enable ccache for faster rebuilds
export CC="ccache gcc"
export CXX="ccache g++"
```

### Compiler Optimization

```bash
# Use faster linker (Linux)
export LDFLAGS="-fuse-ld=gold"  # GCC
export LDFLAGS="-fuse-ld=lld"   # Clang

# Enable compiler caching
export CC="ccache gcc"
export CXX="ccache g++"
```

## Advanced Debugging

### Verbose Build Output

```bash
# CMake verbose build
cmake --build . -j4 --verbose

# Make verbose build
make -j4 V=1 server

# Show actual commands
make -j4 -n server  # dry run
```

### Dependency Analysis

```bash
# Show make dependencies
make -j1 -d server 2>&1 | grep -E "(Considering|Must remake)"

# CMake dependency graph
cmake --graphviz=deps.dot ..
dot -Tpng deps.dot -o deps.png
```

### Build Timing Analysis

```bash
# Time individual targets
time make -j8 common
time make -j8 login
time make -j8 char
time make -j8 map

# Profile build with different job counts
for j in 1 2 4 8 16; do
    echo "=== Testing $j jobs ==="
    make clean >/dev/null 2>&1
    time make -j$j server >/dev/null 2>&1
done
```

## System-Specific Solutions

### Low-Memory Systems (< 4GB RAM)

```bash
# Use minimal job count
make -j2 server

# Build components sequentially
make common
make login
make char
make map
```

### High-Core Systems (16+ cores)

```bash
# May need to limit jobs due to other bottlenecks
OPTIMAL_JOBS=$(($(nproc) * 3 / 4))
make -j$OPTIMAL_JOBS server

# Use Ninja generator for better parallelization
cmake -G Ninja -DENABLE_PARALLEL_BUILD=ON ..
ninja -j16
```

### Network File Systems

```bash
# Parallel builds may be slower on NFS
# Copy to local storage first
rsync -av /nfs/rathena/ /tmp/rathena-local/
cd /tmp/rathena-local/
make -j8 server
```

## Getting Help

If you're still experiencing issues:

1. **Run the diagnostic script:**
   ```bash
   ./configure-parallel.sh > system-info.txt
   ```

2. **Run the test suite:**
   ```bash
   ./test-parallel-build.sh > test-results.txt
   ```

3. **Gather build logs:**
   ```bash
   make -j4 server 2>&1 | tee build-log.txt
   ```

4. **Report the issue** with the generated files on the [rAthena forums](https://rathena.org/board) or [GitHub issues](https://github.com/rathena/rathena/issues).

## Prevention Tips

1. **Regular testing:** Run `./test-build-quick.sh` after system updates
2. **Monitor resources:** Keep an eye on memory and CPU usage
3. **Keep tools updated:** Update CMake, Make, and compilers regularly
4. **Clean builds:** Occasionally do clean builds to catch dependency issues
5. **Backup working configs:** Save working build configurations

---

For more information, see [PARALLEL_BUILD.md](PARALLEL_BUILD.md).
